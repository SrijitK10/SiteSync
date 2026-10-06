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

  // Replace type: 'bigint' with type: Number
  if (content.includes("type: 'bigint'")) {
    content = content.replace(/type:\s*'bigint'/g, "type: Number");
    changed = true;
  }
  
  if (content.includes("type: 'bytea'")) {
    content = content.replace(/type:\s*'bytea'/g, "type: Buffer");
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed bigint/bytea types in', file);
  }
});
