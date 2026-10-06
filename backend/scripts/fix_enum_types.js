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

  // Replace type: 'enum' with type: String
  if (content.includes("type: 'enum'")) {
    content = content.replace(/type:\s*'enum'/g, "type: String");
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed enum types in', file);
  }
});
