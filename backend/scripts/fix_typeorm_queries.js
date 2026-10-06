const fs = require('fs');
const path = require('path');

function fixQueries(file) {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Remove TypeORM imports
  const oldImport = "import { Repository, MoreThanOrEqual, Between, In } from 'typeorm';";
  if (content.includes(oldImport)) {
    content = content.replace(oldImport, "");
    changed = true;
  }
  const oldImport2 = "import { Repository, MoreThanOrEqual, Between } from 'typeorm';";
  if (content.includes(oldImport2)) {
    content = content.replace(oldImport2, "");
    changed = true;
  }
  const oldImport3 = "import { Repository, In } from 'typeorm';";
  if (content.includes(oldImport3)) {
    content = content.replace(oldImport3, "");
    changed = true;
  }
  content = content.replace(/import \{ Repository \} from 'typeorm';\n/g, "");

  // Fix Between
  content = content.replace(/Between\(([^,]+),\s*([^)]+)\)/g, "{ $gte: $1, $lte: $2 }");

  // Fix MoreThanOrEqual
  content = content.replace(/MoreThanOrEqual\(([^)]+)\)/g, "{ $gte: $1 }");

  // Fix In
  content = content.replace(/In\(([^)]+)\)/g, "{ $in: $1 }");

  if (content !== fs.readFileSync(file, 'utf8')) {
    fs.writeFileSync(file, content);
    console.log('Fixed TypeORM queries in', file);
  }
}

fixQueries('backend/src/attendance/attendance.service.ts');
fixQueries('backend/src/tasks/tasks.service.ts');
fixQueries('backend/src/projects/projects.service.ts');
