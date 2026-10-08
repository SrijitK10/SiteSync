import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ConfigService } from '@nestjs/config';
import { AssistantMessage, AssistantMessageDocument, AssistantIntent, AssistantExecutionStatus } from './entities/assistant-message.entity';
import { Project, ProjectDocument } from '../projects/entities/project.entity';
import { Flat, FlatDocument } from '../flats/entities/flat.entity';
import { Contractor, ContractorDocument } from '../contractors/entities/contractor.entity';
import { TasksService } from '../tasks/tasks.service';
import { AttendanceService } from '../attendance/attendance.service';
import { buildIdFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class AssistantService {
  private readonly logger = new Logger(AssistantService.name);

  constructor(
    @InjectModel(AssistantMessage.name)
    private messageRepository: Model<AssistantMessageDocument>,
    @InjectModel(Project.name)
    private projectRepository: Model<ProjectDocument>,
    @InjectModel(Flat.name)
    private flatRepository: Model<FlatDocument>,
    @InjectModel(Contractor.name)
    private contractorRepository: Model<ContractorDocument>,
    private readonly tasksService: TasksService,
    private readonly attendanceService: AttendanceService,
    private readonly configService: ConfigService,
  ) {}

  private getGeminiApiKey(): string | null {
    return (
      process.env.GEMINI_API_KEY ||
      this.configService.get<string>('GEMINI_API_KEY') ||
      null
    );
  }

  /**
   * Main entrypoint: Takes plain text from user, extracts intent & entities,
   * creates an AssistantMessage in DB, and returns it to the client.
   */
  async processUserMessage(rawText: string, user: { id: string; name?: string; role?: string }): Promise<AssistantMessage> {
    if (!rawText || !rawText.trim()) {
      throw new BadRequestException('Message text cannot be empty');
    }

    const trimmedInput = rawText.trim();

    // 1. Fetch available project, flat, and contractor data for accurate entity mapping
    const [projects, flats, contractors] = await Promise.all([
      this.projectRepository.find().select('id name location').lean().exec(),
      this.flatRepository.find().select('id flat_number project_id').lean().exec(),
      this.contractorRepository.find().select('id name').lean().exec(),
    ]);

    const cleanProjects = toCleanObjects<any>(projects);
    const cleanFlats = toCleanObjects<any>(flats);
    const cleanContractors = toCleanObjects<any>(contractors);

    // 2. Parse input using Gemini LLM (or regex fallback if API key not provided)
    let parsedResult = await this.parseWithGemini(trimmedInput, cleanProjects, cleanFlats, cleanContractors);

    if (!parsedResult) {
      parsedResult = this.heuristicFallbackParse(trimmedInput, cleanProjects, cleanFlats, cleanContractors);
    }

    // 3. Format a friendly response
    const reply = this.generateFriendlyReply(parsedResult);

    // 4. Save to assistant_messages collection
    const assistantMessage = new this.messageRepository({
      user_id: user.id,
      user_name: user.name || 'Site User',
      user_role: user.role || 'site_manager',
      raw_input: trimmedInput,
      intent: parsedResult.intent || AssistantIntent.UNKNOWN,
      parsed_data: parsedResult,
      execution_status: AssistantExecutionStatus.PENDING,
      created_record_id: null,
      assistant_reply: reply,
    });

    const saved = await assistantMessage.save();
    return toCleanObject<AssistantMessage>(saved);
  }

  /**
   * LLM Extraction via Google Gemini Flash
   */
  private async parseWithGemini(
    text: string,
    projects: any[],
    flats: any[],
    contractors: any[],
  ): Promise<any | null> {
    const apiKey = this.getGeminiApiKey();
    if (!apiKey) {
      this.logger.warn('GEMINI_API_KEY is not configured. Falling back to heuristic parser.');
      return null;
    }

    const projectContext = projects.map(p => ({ id: p.id, name: p.name, location: p.location }));
    const flatContext = flats.map(f => ({ id: f.id, flat_number: f.flat_number, project_id: f.project_id }));
    const contractorContext = contractors.map(c => ({ id: c.id, name: c.name }));

    const systemPrompt = `You are the intelligent construction site assistant for SiteSync.
Your task is to understand messages written by on-site workers in Bengali script (বাংলা), Romanized Bengali ("Banglish", e.g. "rupayan aster harkash 4 labour 5 mistri"), or English, and classify them into either ATTENDANCE or TASK.

Available Projects:
${JSON.stringify(projectContext)}

Available Flats:
${JSON.stringify(flatContext)}

Available Contractors:
${JSON.stringify(contractorContext)}

Vocabulary & Construction Terms in West Bengal / Bangladesh:
- "labour" / "lebar" / "lebor" / "লেবার" -> labour count
- "mistri" / "rajmistri" / "মিস্ত্রি" -> mason / mistri count
- "maati kata" / "mati kata" / "মাটি কাটা" -> earth excavation / digging workers count
- "santras" / "shantrash" / "shuttering" / "সান্ত্রাস" -> shuttering workers count
- Bengali numbers: এক/1, দুই/2, তিন/3, চার/4, পাঁচ/5, ছয়/6, সাত/7, আট/8, নয়/9, দশ/10
- Task terms: "pending", "baaki", "baki ache", "shesh", "complete", "dhalai", "putty", "plaster", "cement", "tiles", "wiring", "plumbing", "gathuni" / "brickwork".

Classification Rules:
1. If the message mentions worker counts (e.g. 4 labour, 5 mistri, 2 santras) or contractor attendance, classify as "attendance".
2. If the message specifies work to be done, pending tasks, defects, or completion in a project or flat (e.g., "rupayan dahlia 403 cement pending"), classify as "task".
3. Match the project name fuzzy to the closest project in Available Projects and provide its exact project_id.
4. Match flat numbers (e.g. "403", "201", "B-102") to the matching flat for that project_id and provide matched flat_id.
5. If attendance, extract contractor_name (even if new or unlisted), labourers_count, mistris_count, maati_kata_count, santras_count, and work_description.
6. If task, extract title, description, and status ('todo' | 'in_progress' | 'completed').

Respond with ONLY valid JSON strictly adhering to this schema:
{
  "intent": "attendance" | "task" | "unknown",
  "project_id": string | null,
  "project_name": string | null,
  "flat_id": string | null,
  "flat_number": string | null,
  "contractor_name": string | null,
  "labourers_count": number,
  "mistris_count": number,
  "maati_kata_count": number,
  "santras_count": number,
  "work_description": string | null,
  "title": string | null,
  "description": string | null,
  "status": "todo" | "in_progress" | "completed"
}`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [
                { text: systemPrompt },
                { text: `User Message: "${text}"` },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: 'application/json',
          },
        }),
      });

      if (!response.ok) {
        // Fallback to gemini-1.5-flash if 2.0-flash is unavailable
        this.logger.warn(`Gemini 2.0-flash returned ${response.status}, trying gemini-1.5-flash...`);
        return await this.fallbackGemini15(text, systemPrompt, apiKey);
      }

      const data = await response.json();
      const content = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!content) return null;

      const parsed = JSON.parse(content);
      return parsed;
    } catch (e) {
      this.logger.error('Gemini call failed', e);
      return null;
    }
  }

  private async fallbackGemini15(text: string, systemPrompt: string, apiKey: string): Promise<any | null> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              role: 'user',
              parts: [
                { text: systemPrompt },
                { text: `User Message: "${text}"` },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: 'application/json',
          },
        }),
      });
      if (!response.ok) return null;
      const data = await response.json();
      const content = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      return content ? JSON.parse(content) : null;
    } catch (err) {
      this.logger.error('Gemini 1.5 fallback also failed', err);
      return null;
    }
  }

  /**
   * Resilient heuristic parser when AI API key is not present or offline
   */
  private heuristicFallbackParse(text: string, projects: any[], flats: any[], contractors: any[]): any {
    const lower = text.toLowerCase();

    // 1. Match project
    let matchedProject = projects.find(p => lower.includes(p.name.toLowerCase()));
    if (!matchedProject) {
      // Partial match (e.g., "aster" in "Rupayan Aster")
      matchedProject = projects.find(p => {
        const words = (p.name || '').toLowerCase().split(/\s+/);
        return words.some((w: string) => w.length > 3 && lower.includes(w));
      });
    }

    const projectId = matchedProject ? matchedProject.id : (projects[0]?.id || null);
    const projectName = matchedProject ? matchedProject.name : (projects[0]?.name || null);

    // 2. Attendance patterns: numbers followed by labour / mistri / contractor
    const isAttendance =
      lower.includes('labour') ||
      lower.includes('lebar') ||
      lower.includes('mistri') ||
      lower.includes('santras') ||
      lower.includes('mati kata') ||
      lower.includes('attendance');

    if (isAttendance) {
      const labourMatch = lower.match(/(\d+)\s*(?:labour|lebar|lebor|জন লেবার)/i);
      const mistriMatch = lower.match(/(\d+)\s*(?:mistri|rajmistri|জন মিস্ত্রি)/i);
      const santrasMatch = lower.match(/(\d+)\s*(?:santras|shantrash)/i);
      const matiKataMatch = lower.match(/(\d+)\s*(?:mati\s*kata|maati\s*kata)/i);

      let contractorName = null;
      for (const c of contractors) {
        if (lower.includes(c.name.toLowerCase())) {
          contractorName = c.name;
          break;
        }
      }

      if (!contractorName) {
        // Find potential contractor word (e.g. "harkash" in "rupayan aster harkash 4 labour 5 mistri")
        const tokens = text.split(/\s+/);
        const nonKeywords = tokens.filter(t => {
          const lt = t.toLowerCase();
          return !['rupayan', 'aster', 'dahlia', 'labour', 'lebar', 'mistri', 'santras'].includes(lt) && !/\d+/.test(lt);
        });
        if (nonKeywords.length > 0) {
          contractorName = nonKeywords[0];
        }
      }

      return {
        intent: 'attendance',
        project_id: projectId,
        project_name: projectName,
        contractor_name: contractorName || 'General Contractor',
        labourers_count: labourMatch ? parseInt(labourMatch[1], 10) : 0,
        mistris_count: mistriMatch ? parseInt(mistriMatch[1], 10) : 0,
        maati_kata_count: matiKataMatch ? parseInt(matiKataMatch[1], 10) : 0,
        santras_count: santrasMatch ? parseInt(santrasMatch[1], 10) : 0,
        work_description: text,
      };
    }

    // 3. Task pattern: e.g. "rupayan dahlia 403 cement pending"
    // Find flat number (e.g. 3 or 4 digits)
    const flatNumMatch = text.match(/\b(\d{3,4}|[A-Za-z]-?\d{1,3})\b/);
    let matchedFlat = null;
    if (flatNumMatch) {
      const flatNumStr = flatNumMatch[1];
      matchedFlat = flats.find(f => f.flat_number.toLowerCase() === flatNumStr.toLowerCase() && (!projectId || f.project_id === projectId));
    }

    const titleWords = text
      .replace(new RegExp(projectName || '', 'gi'), '')
      .replace(flatNumMatch ? flatNumMatch[0] : '', '')
      .trim();

    return {
      intent: 'task',
      project_id: projectId,
      project_name: projectName,
      flat_id: matchedFlat ? matchedFlat.id : null,
      flat_number: matchedFlat ? matchedFlat.flat_number : (flatNumMatch ? flatNumMatch[1] : null),
      title: titleWords.length > 2 ? titleWords : text,
      description: null,
      status: lower.includes('complete') || lower.includes('shesh') ? 'completed' : 'todo',
    };
  }

  private generateFriendlyReply(parsed: any): string {
    if (parsed.intent === 'attendance') {
      const parts: string[] = [];
      if (parsed.labourers_count) parts.push(`${parsed.labourers_count} Labour`);
      if (parsed.mistris_count) parts.push(`${parsed.mistris_count} Mistri`);
      if (parsed.santras_count) parts.push(`${parsed.santras_count} Santras`);
      if (parsed.maati_kata_count) parts.push(`${parsed.maati_kata_count} Maati Kata`);
      const workersStr = parts.length > 0 ? parts.join(', ') : 'Attendance';
      return `Attendance parsed for ${parsed.project_name || 'Project'} (${parsed.contractor_name || 'Contractor'}): ${workersStr}. Tap confirm to record.`;
    }

    if (parsed.intent === 'task') {
      const flatStr = parsed.flat_number ? ` (Flat ${parsed.flat_number})` : '';
      return `Task parsed for ${parsed.project_name || 'Project'}${flatStr}: "${parsed.title || 'New Task'}". Tap confirm to create.`;
    }

    return `Could not fully understand the entry. Please review and clarify.`;
  }

  /**
   * One-tap Confirmation & Execution
   */
  async executeMessage(messageId: string, user: { id: string; name?: string }): Promise<AssistantMessage> {
    const message = await this.messageRepository.findOne(buildIdFilter(messageId));
    if (!message) {
      throw new NotFoundException('Assistant message not found');
    }

    if (message.execution_status === AssistantExecutionStatus.EXECUTED) {
      return toCleanObject<AssistantMessage>(message);
    }

    const data = message.parsed_data || {};

    if (message.intent === AssistantIntent.TASK) {
      if (!data.project_id) {
        throw new BadRequestException('Cannot create task: Project is required');
      }

      const task = await this.tasksService.create(
        {
          title: data.title || message.raw_input,
          description: data.description || null,
          status: data.status || 'todo',
          projectId: data.project_id,
          flatId: data.flat_id || null,
        },
        user.id,
      );

      message.execution_status = AssistantExecutionStatus.EXECUTED;
      message.created_record_id = task.id;
      message.assistant_reply = `✅ Task "${task.title}" has been successfully created!`;
      await message.save();
      return toCleanObject<AssistantMessage>(message);
    }

    if (message.intent === AssistantIntent.ATTENDANCE) {
      if (!data.project_id) {
        throw new BadRequestException('Cannot record attendance: Project is required');
      }

      await this.attendanceService.createBulk(
        {
          projectId: data.project_id,
          siteAddress: data.project_name || '',
          records: [
            {
              contractor_name: data.contractor_name || 'Contractor',
              labourers_count: data.labourers_count || 0,
              mistris_count: data.mistris_count || 0,
              maati_kata_count: data.maati_kata_count || 0,
              santras_count: data.santras_count || 0,
              work_description: data.work_description || message.raw_input,
              date: new Date(),
            },
          ],
        },
        user.id,
      );

      message.execution_status = AssistantExecutionStatus.EXECUTED;
      message.assistant_reply = `✅ Attendance for ${data.contractor_name || 'Contractor'} recorded successfully!`;
      await message.save();
      return toCleanObject<AssistantMessage>(message);
    }

    throw new BadRequestException('Cannot execute unrecognized intent');
  }

  async cancelMessage(messageId: string): Promise<AssistantMessage> {
    const message = await this.messageRepository.findOne(buildIdFilter(messageId));
    if (!message) {
      throw new NotFoundException('Assistant message not found');
    }
    message.execution_status = AssistantExecutionStatus.CANCELLED;
    message.assistant_reply = '❌ Action cancelled.';
    await message.save();
    return toCleanObject<AssistantMessage>(message);
  }

  /**
   * Get conversational messages for the logged-in user
   */
  async getUserMessages(userId: string, limit = 50): Promise<AssistantMessage[]> {
    const messages = await this.messageRepository
      .find({ user_id: userId })
      .sort({ created_at: -1 })
      .limit(limit)
      .lean()
      .exec();

    return toCleanObjects<AssistantMessage>(messages).reverse();
  }

  /**
   * Supervision Feed for Admin and Super Admin
   * Returns all messages across all workers with optional filters
   */
  async getSupervisionFeed(filters: {
    userId?: string;
    projectId?: string;
    intent?: string;
    status?: string;
    range?: string;
    limit?: number;
  }): Promise<AssistantMessage[]> {
    const query: any = {};

    if (filters.userId) query.user_id = filters.userId;
    if (filters.intent && filters.intent !== 'all') query.intent = filters.intent;
    if (filters.status && filters.status !== 'all') query.execution_status = filters.status;
    if (filters.projectId) query['parsed_data.project_id'] = filters.projectId;

    if (filters.range && filters.range !== 'all') {
      const now = new Date();
      if (filters.range === 'today') {
        const startOfDay = new Date(now.setHours(0, 0, 0, 0));
        query.created_at = { $gte: startOfDay };
      } else if (filters.range === 'week') {
        const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        query.created_at = { $gte: startOfWeek };
      }
    }

    const messages = await this.messageRepository
      .find(query)
      .sort({ created_at: -1 })
      .limit(filters.limit || 100)
      .lean()
      .exec();

    return toCleanObjects<AssistantMessage>(messages);
  }
}
