import hilog from '@ohos.hilog'
import common from '@ohos.app.ability.common'
import Logger from '../common/utils/Logger'
import { createWantAgent, publishNotification } from '../common/utils/NotificationUtil'
import { WantAgent } from '@ohos.app.ability.wantAgent'
import CommonConstants, { DOWNLOAD_STATUS } from '../common/constants/CommonConstants'
import notification from '@ohos.notificationManager'
import promptAction from '@ohos.promptAction'
import { getStringByRes } from '../common/utils/ResourseUtil'
import notificationManager from '@ohos.notificationManager'

@Entry
@Component
struct Index {
    @State downloadProgress: number = 0
    @State downloadStatus: number = DOWNLOAD_STATUS.INITIAL;
    private context = getContext(this) as common.UIAbilityContext
    private wantAgentObj: WantAgent = new Object();
    private interval: number = -1;
    private notificationTitle: string = '';
    private isSupport: boolean = true;

    aboutToAppear() {
        let bundleName = this.context.abilityInfo.bundleName;
        let abilityName = this.context.abilityInfo.name
        createWantAgent(bundleName, abilityName).then(want => {
            this.wantAgentObj = want
        }).catch((error: Error) => {
            Logger.error(`getWantAgent fail,err:${JSON.stringify(error)}`)
        })
        notificationManager.isSupportTemplate('downloadTemplate').then(isSupport => {
            if (!isSupport) {
                promptAction.showToast({
                    message: $r('app.string.invalid_button_toast')
                })
            }
            this.isSupport = isSupport
        })

    }

    build() {
        Column() {
            Text($r('app.string.title'))
                .fontSize($r('app.float.title_font_size'))
                .fontWeight(CommonConstants.FONT_WEIGHT_LAGER)
                .width(CommonConstants.TITLE_WIDTH)
                .textAlign(TextAlign.Start)
                .margin({
                    top: $r('app.float.title_margin_top'),
                    bottom: $r('app.float.title_margin_top')
                })
            Row() {
                Column() {
                    Image($r('app.media.ic_image'))
                        .objectFit(ImageFit.Fill)
                        .width($r('app.float.card_image_length'))
                        .height($r('app.float.card_image_length'))
                }
                .height(CommonConstants.FULL_LENGTH)
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(CommonConstants.IMAGE_WEIGHT)

                Column() {
                    Row() {
                        Text(CommonConstants.DOWNLOAD_FILE)
                            .fontSize($r('app.float.name_font_size'))
                            .textAlign(TextAlign.Center)
                            .fontWeight(CommonConstants.FONT_WEIGHT_LAGER)
                            .lineHeight($r('app.float.name_font_height'))
                        Text(`${this.downloadProgress}%`)
                            .fontSize($r('app.float.normal_font_size'))
                            .lineHeight($r('app.float.name_font_height'))
                            .opacity(CommonConstants.FONT_OPACITY)
                    }
                    .width(CommonConstants.FULL_LENGTH)
                    .justifyContent(FlexAlign.SpaceBetween)

                    Progress({
                        value: this.downloadProgress,
                        total: CommonConstants.PROGRESS_TOTAL
                    })
                        .width(CommonConstants.FULL_LENGTH)
                    Row() {
                        Text(CommonConstants.FILE_SIZE)
                            .fontSize($r('app.float.normal_font_size'))
                            .lineHeight($r('app.float.name_font_height'))
                            .opacity(CommonConstants.FONT_OPACITY)
                        if (this.downloadStatus === DOWNLOAD_STATUS.INITIAL) {
                            this.customButton($r('app.string.button_download'),():Promise<void> => this.start())
                        } else if (this.downloadStatus === DOWNLOAD_STATUS.DOWNLOADING) {
                            Row() {
                                this.cancelButton()
                                this.customButton($r('app.string.button_pause'),():Promise<void> => this.pause())
                            }
                        } else if (this.downloadStatus === DOWNLOAD_STATUS.PAUSE) {
                            Row() {
                                this.cancelButton()
                                this.customButton($r('app.string.button_resume'), (): Promise<void> => this.resume())
                            }
                        } else {
                            this.customButton($r('app.string.button_finish'), (): void => this.open())
                        }
                    }
                    .width(CommonConstants.FULL_LENGTH)
                    .justifyContent(FlexAlign.SpaceBetween)
                }
                .layoutWeight(CommonConstants.CARD_CONTENT_WEIGHT)
                .height(CommonConstants.FULL_LENGTH)
                .justifyContent(FlexAlign.SpaceBetween)

            }
            .width(CommonConstants.CARD_WIDTH)
            .height($r('app.float.card_height'))
            .backgroundColor(Color.White)
            .justifyContent(FlexAlign.Center)
            .padding($r('app.float.card_padding'))
        }
        .width(CommonConstants.FULL_LENGTH)
        .height(CommonConstants.FULL_LENGTH)
        .backgroundColor($r('app.color.index_background_color'))
    }

    download() {
        this.interval = setInterval(async () => {
            if (this.downloadProgress === CommonConstants.PROGRESS_TOTAL) {
                this.notificationTitle = await getStringByRes($r('app.string.notification_title_finish'), this)
                this.downloadStatus = DOWNLOAD_STATUS.FINISHED
                clearInterval(this.interval)
            } else {
                this.downloadProgress += CommonConstants.PROGRESS_SPEED
            }
            if (this.isSupport) {
                publishNotification(this.downloadProgress, this.notificationTitle, this.wantAgentObj)
            }
        }, CommonConstants.UPDATE_FREQUENCY)
    }

    async start() {
        this.notificationTitle = await getStringByRes($r('app.string.notification_title_download'), this);
        this.downloadStatus = DOWNLOAD_STATUS.DOWNLOADING;
        this.downloadProgress = 0;
        this.download();
        return
    }

    /**
     * Click pause.
     */
    async pause() {
        this.notificationTitle = await getStringByRes($r('app.string.notification_title_pause'), this);
        clearInterval(this.interval);
        this.downloadStatus = DOWNLOAD_STATUS.PAUSE;
        if (this.isSupport) {
            publishNotification(this.downloadProgress, this.notificationTitle, this.wantAgentObj);
        }
    }

    /**
     * Click resume.
     */
    async resume() {
        this.notificationTitle = await getStringByRes($r('app.string.notification_title_download'), this);
        this.download();
        this.downloadStatus = DOWNLOAD_STATUS.DOWNLOADING;
    }

    async cancel() {
        this.downloadProgress = 0;
        clearInterval(this.interval);
        this.downloadStatus = DOWNLOAD_STATUS.INITIAL;
        notification.cancel(CommonConstants.NOTIFICATION_ID);
    }

    open() {
        promptAction.showToast({
            message: $r('app.string.invalid_button_toast')
        })
    }

    @Builder customButton(textResource: Resource, click: Function = () => {
    }) {
        Button(textResource)
            .backgroundColor($r('app.color.button_color'))
            .buttonStyle()
            .onClick(() => {
                click();
            })
    }

    @Builder cancelButton() {
        Button($r('app.string.button_cancel'))
            .backgroundColor($r('app.color.cancel_button_color'))
            .buttonStyle()
            .fontColor($r('app.color.button_color'))
            .margin({ right: $r('app.float.button_margin') })
            .onClick(() => {
                this.cancel();
            })
    }
}

@Extend(Button) function buttonStyle() {
    .constraintSize({ minWidth: $r('app.float.button_width') })
    .height($r('app.float.button_height'))
    .borderRadius($r('app.float.button_border_radius'))
    .fontSize($r('app.float.button_font_size'))
}
