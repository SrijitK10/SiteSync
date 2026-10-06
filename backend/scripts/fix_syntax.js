const fs = require('fs');
const path = require('path');

function fixSyntax(file) {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Fix the syntax error in attendance and tasks service
  // '{ $gte: new Date(ms - X }.toISOString().split('T')[0])'
  // to '{ $gte: new Date(ms - X).toISOString().split('T')[0] }'

  if (content.includes('}.toISOString')) {
    content = content.replace(/\{ \$gte: new Date\(([^}]+)\}\.toISOString\(\)\.split\('T'\)\[0\]\)/g, "{ $gte: new Date($1).toISOString().split('T')[0] }");
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed syntax in', file);
  }
}

fixSyntax('backend/src/attendance/attendance.service.ts');
fixSyntax('backend/src/tasks/tasks.service.ts');
