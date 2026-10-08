import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AssistantService } from './assistant.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('assistant')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  /**
   * Send a text message to the AI Assistant
   */
  @Post('message')
  async sendMessage(@Body() body: { text: string }, @Request() req: any) {
    const user = {
      id: req.user?.id || req.user?.userId || req.user?.sub,
      name: req.user?.name,
      role: req.user?.role,
    };
    return this.assistantService.processUserMessage(body.text, user);
  }

  /**
   * One-tap confirmation to commit the parsed task/attendance to DB
   */
  @Post('execute/:id')
  async executeAction(@Param('id') id: string, @Request() req: any) {
    const user = {
      id: req.user?.id || req.user?.userId || req.user?.sub,
      name: req.user?.name,
    };
    return this.assistantService.executeMessage(id, user);
  }

  /**
   * Cancel an action
   */
  @Post('cancel/:id')
  async cancelAction(@Param('id') id: string) {
    return this.assistantService.cancelMessage(id);
  }

  /**
   * Get conversational chat history for currently logged-in user
   */
  @Get('messages/my')
  async getMyMessages(@Request() req: any) {
    const userId = req.user?.id || req.user?.userId || req.user?.sub;
    return this.assistantService.getUserMessages(userId);
  }

  /**
   * Supervision Feed: Full company-wide audit log for Admin and Super Admin
   */
  @Get('supervision/all')
  @Roles('admin', 'super_admin')
  async getSupervisionFeed(
    @Query('userId') userId?: string,
    @Query('projectId') projectId?: string,
    @Query('intent') intent?: string,
    @Query('status') status?: string,
    @Query('range') range?: string,
  ) {
    return this.assistantService.getSupervisionFeed({
      userId,
      projectId,
      intent,
      status,
      range,
    });
  }
}
