import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { logger } from '@chenchl/gmlogger';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    logger.init(this.context, {
      tag: 'testTag111',
      domain: 0x0022,
      isLogToFile: true,
      enable: true,
      isHilog: true,
      showLogLocation: true,
      logSize: 1024,
      stackTraceNum: 4,
      encryptKey: new Uint8Array([7, 154, 52, 176, 4, 236, 150, 43, 237, 9, 145, 166, 141, 174, 224, 131])
    })
    logger.info('Ability onCreate', 'testTag')
  }

  onDestroy(): void {
    logger.info('Ability onDestroy', 'testTag')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    logger.info('Ability onWindowStageCreate', 'testTag')

    windowStage.loadContent('pages/Index', (err) => {
      //windowStage.getMainWindowSync().setWindowLayoutFullScreen(true)
      if (err.code) {
        logger.error(`Failed to load the content. Cause: ${JSON.stringify(err) ?? ''}`, 'testTag')
        return;
      }
      logger.info('Succeeded in loading the content.', 'testTag')
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    logger.info('Ability onWindowStageDestroy', 'testTag')
  }

  onForeground(): void {
    // Ability has brought to foreground
    logger.info('Ability onForeground', 'testTag')
  }

  onBackground(): void {
    // Ability has back to background
    logger.info('Ability onBackground', 'testTag')
  }
}