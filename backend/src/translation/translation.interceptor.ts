import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { TranslationService } from './translation.service';

@Injectable()
export class TranslationInterceptor implements NestInterceptor {
  constructor(private readonly translationService: TranslationService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const langHeader = request.headers['accept-language'];
    
    // Extract base language code (e.g. "hi-IN,hi;q=0.9" -> "hi")
    const lang = langHeader ? langHeader.split('-')[0].split(',')[0].trim().toLowerCase() : 'en';

    return next.handle().pipe(
      map(async data => {
        // We only translate if lang is not 'en' or not default
        if (lang === 'en') return data;
        
        const translateObj = async (obj: any): Promise<any> => {
          if (!obj) return obj;
          if (Array.isArray(obj)) {
            return Promise.all(obj.map((item: any) => translateObj(item)));
          }
          if (typeof obj === 'object') {
            const newObj = { ...obj };

            // Swap title if translations exist
            if (newObj.title && newObj.title_translations && newObj.title_translations[lang]) {
              newObj.title = newObj.title_translations[lang];
            } else if (newObj.title && newObj.title_translations && !newObj.title_translations[lang]) {
              // On-the-fly: translate title if translation is missing
              try {
                const result = await this.translationService.translateText(newObj.title, [lang]);
                if (result[lang]) {
                  newObj.title = result[lang];
                }
              } catch (e) {
                // Silently fail – keep original title
              }
            }

            // Swap description if translations exist
            if (newObj.description && newObj.description_translations && newObj.description_translations[lang]) {
              newObj.description = newObj.description_translations[lang];
            } else if (newObj.description && newObj.description_translations && !newObj.description_translations[lang]) {
              // On-the-fly: translate description if translation is missing
              try {
                const result = await this.translationService.translateText(newObj.description, [lang]);
                if (result[lang]) {
                  newObj.description = result[lang];
                }
              } catch (e) {
                // Silently fail – keep original description
              }
            }

            // Recursively process nested objects like 'project' or 'flat'
            for (const key of Object.keys(newObj)) {
              if (typeof newObj[key] === 'object' && newObj[key] !== null && !Array.isArray(newObj[key])) {
                newObj[key] = await translateObj(newObj[key]);
              }
            }
            return newObj;
          }
          return obj;
        };

        return translateObj(data);
      }),
    );
  }
}
