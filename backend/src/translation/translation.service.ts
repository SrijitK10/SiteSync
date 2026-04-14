import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class TranslationService {
  private readonly logger = new Logger(TranslationService.name);
  private readonly endpoint = 'https://api.cognitive.microsofttranslator.com/translate?api-version=3.0';

  constructor(private configService: ConfigService) {}

  async translateText(text: string, targetLanguages: string[]): Promise<Record<string, string>> {
    if (!text || targetLanguages.length === 0) return {};

    const apiKey = process.env.AZURE_TRANSLATOR_KEY || this.configService.get<string>('AZURE_TRANSLATOR_KEY');
    const region = process.env.AZURE_TRANSLATOR_REGION || this.configService.get<string>('AZURE_TRANSLATOR_REGION');

    if (!apiKey) {
      this.logger.warn('Azure Translator Key is missing. Skipping dynamic translation.');
      return {};
    }

    try {
      const languageParams = targetLanguages.map(lang => `to=${lang}`).join('&');
      const url = `${this.endpoint}&${languageParams}`;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Ocp-Apim-Subscription-Key': apiKey,
          'Ocp-Apim-Subscription-Region': region || 'global',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify([{ text }]),
      });

      if (!response.ok) {
        throw new Error(`Azure Translation Error: ${response.statusText}`);
      }

      const data = await response.json();
      const translations = data[0]?.translations || [];

      const result: Record<string, string> = {};
      translations.forEach((t: any) => {
        result[t.to] = t.text;
      });

      return result;
    } catch (e) {
      this.logger.error('Translation failed', e);
      return {};
    }
  }
}
