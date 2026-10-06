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

const serviceFiles = findFiles('backend/src', '.service.ts');
serviceFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Fix result.affected
  if (content.includes('result.affected === 0')) {
    content = content.replace(/result\.affected === 0/g, '!result');
    changed = true;
  }

  // Fix save() leftovers
  if (content.match(/await this\.\w+\.save\(/)) {
    content = content.replace(/await this\.([a-zA-Z0-9_]+)\.save\(([a-zA-Z0-9_]+)\)/g, `await new this.$1($2).save() as any`);
    changed = true;
  }

  // Fix task.service.ts createQueryBuilder
  if (content.includes('.createQueryBuilder')) {
    // replace createQueryBuilder in tasks.service.ts
    content = content.replace(/\.createQueryBuilder\('attachment'\)[\s\S]*?\.getMany\(\)/, `.find({ task: { $in: taskIds } }).exec() as any`);
    changed = true;
  }
  
  // Fix assignments on Promise<null> (like shift.user = ...)
  // The error comes because `shift = await repo.findOne(...)` returns Promise? No, it's missing `await`.
  // Wait, the error is `Property 'user' does not exist on type 'Promise<null>'`. This means the code did `const shift = this.repo.create()`, which in mongoose returns the model directly, but earlier I replaced `.create` with `new this.repo`. 
  // Let's replace `const task = this.tasksRepository.create(` with `const task = new this.tasksRepository(`
  if (content.includes('.create(')) {
    content = content.replace(/this\.([a-zA-Z0-9_]+)\.create\(/g, `new this.$1(`);
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
  }
});

console.log('Fixed affected, save, createQueryBuilder, and create calls.');
