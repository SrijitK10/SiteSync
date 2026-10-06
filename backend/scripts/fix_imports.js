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

// 1. Fix Entities
const entityFiles = findFiles('backend/src', '.entity.ts');
entityFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Add id?: string; back to the class definition
  if (!content.includes('id?: string;')) {
    content = content.replace(/(export class \w+ \{)/, "$1\n  id?: string;");
    changed = true;
  }

  // Remove leftover typeorm decorators if any
  if (content.match(/@(Column|ManyToOne|JoinColumn|OneToMany|OneToOne|Index|CreateDateColumn|UpdateDateColumn)/)) {
    content = content.replace(/@Column\([^)]*\)/g, '@Prop({ type: Object })');
    content = content.replace(/@ManyToOne\([^)]*\)/g, '// @ManyToOne');
    content = content.replace(/@JoinColumn\([^)]*\)/g, '// @JoinColumn');
    content = content.replace(/@OneToMany\([^)]*\)/g, '// @OneToMany');
    content = content.replace(/@OneToOne\([^)]*\)/g, '// @OneToOne');
    content = content.replace(/@Index\([^)]*\)/g, '// @Index');
    content = content.replace(/@CreateDateColumn\([^)]*\)/g, '// @CreateDateColumn');
    content = content.replace(/@UpdateDateColumn\([^)]*\)/g, '// @UpdateDateColumn');
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed entity:', file);
  }
});

// 2. Fix Modules (Missing Schema imports)
const moduleFiles = findFiles('backend/src', '.module.ts');
moduleFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  // Find all schema definitions inside MongooseModule.forFeature
  const schemaRegex = /schema:\s*(\w+Schema)/g;
  let match;
  while ((match = schemaRegex.exec(content)) !== null) {
    const schemaName = match[1];
    if (!content.includes(schemaName + ' } from') && !content.includes(schemaName + '} from')) {
      // Find the entity name to figure out the import
      const entityName = schemaName.replace('Schema', '');
      // Look for the import of the entity
      const importRegex = new RegExp(`import \\{.*?\\b${entityName}\\b.*?\\} from '([^']+)'`);
      const importMatch = content.match(importRegex);
      if (importMatch) {
        // Add Schema to the import
        const oldImport = importMatch[0];
        const newImport = oldImport.replace('{', `{ ${schemaName}, `);
        content = content.replace(oldImport, newImport);
        changed = true;
      }
    }
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed module:', file);
  }
});

// 3. Fix Services (Missing Document imports)
const serviceFiles = findFiles('backend/src', '.service.ts');
serviceFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  const docRegex = /Model<(\w+Document)>/g;
  let match;
  while ((match = docRegex.exec(content)) !== null) {
    const docName = match[1];
    if (!content.includes(docName + ' } from') && !content.includes(docName + '} from')) {
      const entityName = docName.replace('Document', '');
      const importRegex = new RegExp(`import \\{.*?\\b${entityName}\\b.*?\\} from '([^']+)'`);
      const importMatch = content.match(importRegex);
      if (importMatch) {
        const oldImport = importMatch[0];
        const newImport = oldImport.replace('{', `{ ${docName}, `);
        content = content.replace(oldImport, newImport);
        changed = true;
      }
    }
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Fixed service:', file);
  }
});

console.log('Automated fixes complete.');
