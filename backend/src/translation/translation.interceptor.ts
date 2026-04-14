import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class TranslationInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const langHeader = request.headers['accept-language'];
    
    // Extract base language code (e.g. "hi-IN,hi;q=0.9" -> "hi")
    const lang = langHeader ? langHeader.split('-')[0].split(',')[0].trim().toLowerCase() : 'en';

    return next.handle().pipe(
      map(data => {
        // We only translate if lang is not 'en' or not default
        if (lang === 'en') return data;
        
        const translateObj = (obj: any): any => {
          if (!obj) return obj;
          if (Array.isArray(obj)) {
            return obj.map((item: any) => translateObj(item));
          }
          if (typeof obj === 'object') {
            const newObj = { ...obj };
            if (newObj.title_translations && newObj.title_translations[lang]) {
              newObj.title = newObj.title_translations[lang];
            }
            if (newObj.description_translations && newObj.description_translations[lang]) {
              newObj.description = newObj.description_translations[lang];
            }
            // recursively process nested like 'project' or 'flat' if they had translations
            for (const key of Object.keys(newObj)) {
                if (typeof newObj[key] === 'object' && newObj[key] !== null && !Array.isArray(newObj[key])) {
                    newObj[key] = translateObj(newObj[key]);
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
