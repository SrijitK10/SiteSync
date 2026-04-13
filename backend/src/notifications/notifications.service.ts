import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UsersService } from '../users/users.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly usersService: UsersService) {}

  async sendNotification(
    title: string,
    body: string,
    recipientRoles: string[],
    excludeUserId: string,
    data?: any,
    projectId?: string,
  ) {
    try {
      const tokens = await this.usersService.findTokensByRoles(
        recipientRoles,
        excludeUserId,
        projectId,
      );

      if (!tokens || tokens.length === 0) {
        this.logger.log(`No tokens found for roles ${recipientRoles.join(', ')}`);
        return;
      }

      const message: admin.messaging.MulticastMessage = {
        notification: {
          title,
          body,
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.log(
        `Successfully sent ${response.successCount} messages. Failed: ${response.failureCount}`,
      );

      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            this.logger.error(`Failed to send to token ${tokens[idx]}: ${resp.error}`);
            // Logic to remove invalid tokens could go here
          }
        });
      }
    } catch (error) {
      this.logger.error('Error sending notification:', error);
    }
  }
}
