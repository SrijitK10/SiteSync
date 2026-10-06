const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

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
  if (content.includes('@nestjs/mongoose')) return; // already refactored

  // Class name extraction
  const classNameMatch = content.match(/export class (\w+)/);
  const className = classNameMatch ? classNameMatch[1] : 'Unknown';

  // Import replacements
  content = content.replace(/import \{.*?\} from 'typeorm';/s, `import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';\nimport { Document, Types } from 'mongoose';\n\nexport type ${className}Document = ${className} & Document;`);
  
  // Entity to Schema
  content = content.replace(/@Entity\('([^']+)'\)/g, `@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: '$1' })`);
  content = content.replace(/@Entity\(\)/g, `@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } })`);
  
  // Remove PrimaryGeneratedColumn
  content = content.replace(/@PrimaryGeneratedColumn\([^)]*\)\s*\n\s*id:\s*string;/g, `// id is natively handled by Mongoose as _id (ObjectId)`);
  
  // Columns
  content = content.replace(/@Column\(\{([^}]*)\}\)/g, (match, inner) => {
    return `@Prop({${inner}})`;
  });
  content = content.replace(/@Column\(\)/g, `@Prop()`);
  content = content.replace(/@CreateDateColumn\(\)/g, `// @CreateDateColumn()`);
  content = content.replace(/@UpdateDateColumn\(\)/g, `// @UpdateDateColumn()`);
  content = content.replace(/@Index\(\)/g, `// @Index() - handled in @Prop`);

  // Relations (Naive replacement, will require manual fix for complex Types)
  content = content.replace(/@ManyToOne\([^)]*\)\n\s*@JoinColumn\(\{ name: '([^']+)' \}\)\n\s*([a-zA-Z0-9_]+):\s*([a-zA-Z0-9_]+);/g, `@Prop({ type: String, ref: '$3' })\n  $2: string; // foreign key to $3`);
  
  content = content.replace(/@ManyToOne\([^)]*\)\n\s*([a-zA-Z0-9_]+):\s*([a-zA-Z0-9_]+);/g, `@Prop({ type: String, ref: '$2' })\n  $1: string; // foreign key to $2`);

  content = content.replace(/@OneToMany\([^)]*\)\n\s*([a-zA-Z0-9_]+):\s*([a-zA-Z0-9_]+)\[\];/g, `@Prop({ type: [{ type: String, ref: '$2' }] })\n  $1: string[]; // refs to $2`);
  
  content = content.replace(/@OneToOne\([^)]*\)\n\s*@JoinColumn\(\{ name: '([^']+)' \}\)\n\s*([a-zA-Z0-9_]+):\s*([a-zA-Z0-9_]+);/g, `@Prop({ type: String, ref: '$3', unique: true })\n  $2: string; // one-to-one to $3`);

  // Add schema factory
  content += `\nexport const ${className}Schema = SchemaFactory.createForClass(${className});\n`;
  
  fs.writeFileSync(file, content);
  console.log(`Refactored Entity: ${file}`);
});

const moduleFiles = findFiles('backend/src', '.module.ts');
moduleFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  if (content.includes('TypeOrmModule.forFeature')) {
    content = content.replace(/import \{ TypeOrmModule \} from '@nestjs\/typeorm';/, `import { MongooseModule } from '@nestjs/mongoose';`);
    
    // Find all TypeOrmModule.forFeature([A, B, C])
    content = content.replace(/TypeOrmModule\.forFeature\(\[\s*([^\]]+)\s*\]\)/g, (match, entitiesStr) => {
      const entities = entitiesStr.split(',').map(e => e.trim()).filter(e => e);
      const schemaDefs = entities.map(e => `{ name: ${e}.name, schema: ${e}Schema }`).join(', ');
      
      // We also need to add import for Schema... this is tricky so we'll just append it to the top
      entities.forEach(e => {
        if (!content.includes(`${e}Schema`)) {
          content = content.replace(`import { ${e} }`, `import { ${e}, ${e}Schema }`);
        }
      });
      return `MongooseModule.forFeature([${schemaDefs}])`;
    });
    
    fs.writeFileSync(file, content);
    console.log(`Refactored Module: ${file}`);
  }
});

const serviceFiles = findFiles('backend/src', '.service.ts');
serviceFiles.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;
  if (content.includes('@InjectRepository')) {
    content = content.replace(/import \{ InjectRepository \} from '@nestjs\/typeorm';/, `import { InjectModel } from '@nestjs/mongoose';`);
    content = content.replace(/import \{ Repository \} from 'typeorm';/, `import { Model } from 'mongoose';`);
    
    // Convert injections
    content = content.replace(/@InjectRepository\(([a-zA-Z0-9_]+)\)\n\s*(private|public|protected|readonly)?\s*([a-zA-Z0-9_]+):\s*Repository<[a-zA-Z0-9_]+>,?/g, (match, entity, modifier, repoName) => {
      // need to import Document type
      if (!content.includes(`${entity}Document`)) {
        content = content.replace(`import { ${entity} }`, `import { ${entity}, ${entity}Document }`);
      }
      return `@InjectModel(${entity}.name)\n    ${modifier || 'private'} ${repoName}: Model<${entity}Document>,`;
    });
    
    changed = true;
  }
  
  if (changed) {
    fs.writeFileSync(file, content);
    console.log(`Refactored Service Injections: ${file}`);
  }
});

console.log('Automated boilerplate refactoring complete.');
