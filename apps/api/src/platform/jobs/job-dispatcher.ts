import { Injectable, Logger, type OnApplicationBootstrap } from '@nestjs/common';
import { DiscoveryService } from '@nestjs/core';
import { prototypeMethods } from '../methods.js';
import { ON_JOB, type JobEvent } from './on-job.js';

type Handler = (event: JobEvent) => Promise<unknown>;

/** Finds @OnJob handlers across all modules and invokes the one for a topic. */
@Injectable()
export class JobDispatcher implements OnApplicationBootstrap {
  private readonly logger = new Logger('JobDispatcher');
  private readonly handlers = new Map<string, Handler>();

  constructor(private readonly discovery: DiscoveryService) {}

  onApplicationBootstrap(): void {
    for (const wrapper of this.discovery.getProviders()) {
      const instance: unknown = wrapper.instance;
      if (typeof instance !== 'object' || instance === null) continue;
      for (const [, method] of prototypeMethods(instance)) {
        const topic = Reflect.getMetadata(ON_JOB, method) as string | undefined;
        if (!topic) continue;
        if (this.handlers.has(topic)) throw new Error(`Two handlers for job topic ${topic}`);
        this.handlers.set(topic, (event) => method.call(instance, event) as Promise<unknown>);
      }
    }
  }

  topics(): string[] {
    return [...this.handlers.keys()];
  }

  async dispatch(event: JobEvent): Promise<void> {
    const handler = this.handlers.get(event.topic);
    if (!handler) {
      this.logger.warn(`No handler for job topic ${event.topic}; dropping`);
      return;
    }
    await handler(event);
  }
}
