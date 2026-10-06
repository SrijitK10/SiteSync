const fs = require('fs');
const path = require('path');

function findFiles(dir, ext) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(findFiles(file, ext));
    } else if (file.endsWith(ext)) {
      results.push(file);
    }
  });
  return results;
}

const entityFiles = findFiles('backend/src', '.entity.ts');
entityFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Replace invalid types
  const replacements = [
    { regex: /type:\s*'text'/g, replacement: "type: String" },
    { regex: /type:\s*'date'/g, replacement: "type: Date" },
    { regex: /type:\s*'timestamp'/g, replacement: "type: Date" },
    { regex: /type:\s*'jsonb'/g, replacement: "type: Object" },
    { regex: /type:\s*'json'/g, replacement: "type: Object" },
    { regex: /type:\s*'decimal'/g, replacement: "type: Number" },
    { regex: /type:\s*'int'/g, replacement: "type: Number" }
  ];

  replacements.forEach(({ regex, replacement }) => {
    if (regex.test(content)) {
      content = content.replace(regex, replacement);
      changed = true;
    }
  });

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed types in', file);
  }
});
