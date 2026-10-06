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

  // Replace common typeorm leftover types
  const replacements = [
    { regex: /type:\s*'varchar'/g, replacement: "type: String" },
    { regex: /type:\s*'uuid'/g, replacement: "type: String" },
    { regex: /type:\s*'boolean'/g, replacement: "type: Boolean" },
    { regex: /type:\s*'numeric'/g, replacement: "type: Number" },
    { regex: /type:\s*'float'/g, replacement: "type: Number" },
    { regex: /type:\s*'double'/g, replacement: "type: Number" }
  ];

  replacements.forEach(({ regex, replacement }) => {
    if (regex.test(content)) {
      content = content.replace(regex, replacement);
      changed = true;
    }
  });

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed extra types in', file);
  }
});
