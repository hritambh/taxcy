// Writes the OpenAPI document built from the route contracts (run after `build`).
import { writeFileSync } from 'node:fs';
import { allRoutes, buildOpenApiDocument } from '../dist/index.js';

const out = process.argv[2];
if (!out) {
  process.stderr.write('usage: write-openapi.mjs <output.json>\n');
  process.exit(1);
}
const document = buildOpenApiDocument(allRoutes, { title: 'Taxcy API', version: '0.1.0' });
writeFileSync(out, `${JSON.stringify(document, null, 2)}\n`);
