import notification from '@ohos.notificationManager';
import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';
import CommonConstants from '../constants/CommonConstants'
import Logger from '../utils/Logger'

export function createWantAgent(bundleName: string, abilityName: string): Promise<WantAgent> {
    let wantAgentInfo = {
        wants: [
            {
                bundleName: bundleName,
                abilityName: abilityName
            }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    } as wantAgent.WantAgentInfo
    return wantAgent.getWantAgent(wantAgentInfo)
}

export function publishNotification(progress: number, title: string, wantAgentObj: WantAgent) {
    let template: notification.NotificationTemplate = {
        name: 'downloadTemplate',
        data: {
            progressValue: progress,
            progressMaxValue: CommonConstants.PROGRESS_TOTAL,
            isProgressIndeterminate: false
        }
    }
    let notificationRequest: notification.NotificationRequest = {
        id: CommonConstants.NOTIFICATION_ID,
        template: template,
        content: {
            contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
                title: title,
                text: '',
                additionalText: `${progress}%`
            }
        },
        wantAgent: wantAgentObj
    }
    notification.publish(notificationRequest).catch((err: Error) => {
        Logger.error(`[ANS] publish failed,message is ${err}`)
    })

}