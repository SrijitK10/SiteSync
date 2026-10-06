import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
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

// Security configuration for MongoDB connection
function parseMongoOptions(configService: ConfigService) {
  return {
    tls: true,
    tlsAllowInvalidCertificates: false,
    minPoolSize: 5,
    maxPoolSize: 50,
  };
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CacheModule.register({ isGlobal: true, ttl: 5000 }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI'),
        ...parseMongoOptions(configService),
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
