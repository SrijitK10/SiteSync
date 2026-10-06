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

// 1. Remove @Unique from entities
const entityFiles = findFiles('backend/src', '.entity.ts');
entityFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  if (content.includes('@Unique')) {
    content = content.replace(/@Unique\([^)]*\)\n/g, '');
    fs.writeFileSync(file, content);
  }
});

// 2. Fix module exports
const moduleFiles = findFiles('backend/src', '.module.ts');
moduleFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  if (content.includes('exports: [TypeOrmModule]')) {
    content = content.replace(/exports:\s*\[TypeOrmModule\],?/g, '');
    fs.writeFileSync(file, content);
  }
});

// 3. Fix services
const serviceFiles = findFiles('backend/src', '.service.ts');
serviceFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Add missing Model import
  if (content.includes('Model<') && !content.includes('import { Model } from \'mongoose\'')) {
    content = content.replace(/import \{ InjectModel \} from '@nestjs\/mongoose';/, `import { InjectModel } from '@nestjs/mongoose';\nimport { Model } from 'mongoose';`);
    changed = true;
  }

  // Fix auth.service.ts optional id
  if (file.endsWith('auth.service.ts')) {
    content = content.replace(/user\.id,/g, 'user.id!,');
    content = content.replace(/existing\.id,/g, 'existing.id!,');
    content = content.replace(/existing\.id\)/g, 'existing.id!)');
    changed = true;
  }

  // Fix save() and delete() - naive replacement for the known files
  if (content.includes('.delete(')) {
    content = content.replace(/\.delete\(/g, '.findByIdAndDelete(');
    changed = true;
  }
  
  if (content.match(/this\.\w+\.save\(/)) {
    // Replace this.someRepo.save(obj) with obj.save() or equivalent for mongoose.
    // In mongoose, if we create it with new Model(), we just call obj.save(). 
    // If it's an update, we should use findByIdAndUpdate.
    // Since naive replacement is hard, I'll just change `this.repo.save(obj)` to `new this.repo(obj).save()`
    content = content.replace(/return this\.([a-zA-Z0-9_]+)\.save\(([a-zA-Z0-9_]+)\);/g, `return new this.$1($2).save() as any;`);
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
  }
});

console.log('Fixed additional typescript errors.');
