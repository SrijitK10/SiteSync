import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ProjectsModule } from './projects/projects.module';
import { ShiftsModule } from './shifts/shifts.module';
import { TasksModule } from './tasks/tasks.module';
import { AttendanceModule } from './attendance/attendance.module';
import { ContractorsModule } from './contractors/contractors.module';
import { FlatsModule } from './flats/flats.module';
import { CacheModule } from '@nestjs/cache-manager';
import { NotificationsModule } from './notifications/notifications.module';
import { TranslationModule } from './translation/translation.module';

function parseDatabaseSsl(configService: ConfigService) {
  const explicit = configService.get<string>('DATABASE_SSL');
  if (explicit !== undefined) {
    return ['1', 'true', 'yes', 'require'].includes(explicit.toLowerCase())
      ? { rejectUnauthorized: false }
      : false;
  }

  const databaseUrl = configService.get<string>('DATABASE_URL') || '';
  if (/localhost|127\.0\.0\.1|::1/i.test(databaseUrl)) {
    return false;
  }

  return { rejectUnauthorized: false };
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CacheModule.register({ isGlobal: true, ttl: 5000 }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        autoLoadEntities: true,
        synchronize: true, // For dev only
        ssl: parseDatabaseSsl(configService),
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    UsersModule,
    ProjectsModule,
    ShiftsModule,
    TasksModule,
    AttendanceModule,
    ContractorsModule,
    FlatsModule,
    NotificationsModule,
    TranslationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
