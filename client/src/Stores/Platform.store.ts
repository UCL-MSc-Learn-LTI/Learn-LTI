import { observable, action } from 'mobx';
import { ChildStore } from './Core';
import { PlatformService } from '../Services/Platform.service';
import { Platform } from '../Models/Platform.model';
import { ServiceError } from '../Core/Utils/Axios/ServiceError';

export type PlatformSaveResult = 'error' | 'success';

export class PlatformStore extends ChildStore {
  @observable platform: Platform | null = null;
  @observable saveResult: PlatformSaveResult | null = null;
  @observable isSaving = false;
  @observable serviceError : ServiceError | undefined = undefined;

  @action
  async initializePlatform(): Promise<void> {
    const platforms = await PlatformService.getAllPlatforms();

    if (platforms.error) {
      this.serviceError=platforms.error;
    } else {
      if (platforms.length > 0) {
        this.platform = platforms[0];
      } else {
        const newPlatform = await PlatformService.getNewPlatform();

        if (!newPlatform.error) {
          this.platform = newPlatform;
        }
      }
    }
  }

  @action
  async updatePlatform(platform: Platform): Promise<void> {
    this.platform = platform;
    this.saveResult = null;
    this.isSaving = true;
    const hasErrors = await PlatformService.updatePlatform(platform);
    this.isSaving = false;
    this.saveResult = hasErrors ? 'error' : 'success';
  }
}
