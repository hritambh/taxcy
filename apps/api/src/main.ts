import './instrument.js';
import 'reflect-metadata';
import { createApp } from './app.js';
import { APP_CONFIG, type AppConfig } from './platform/config.js';

const app = await createApp();
await app.listen(app.get<AppConfig>(APP_CONFIG).PORT);
