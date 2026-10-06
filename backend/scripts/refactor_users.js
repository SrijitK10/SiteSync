const fs = require('fs');

const servicePath = 'backend/src/users/users.service.ts';
let service = fs.readFileSync(servicePath, 'utf8');

// Replace imports
service = service.replace(/import \{ InjectRepository \} from '@nestjs\/typeorm';\nimport \{ Repository \} from 'typeorm';/g, "import { InjectModel } from '@nestjs/mongoose';\nimport { Model } from 'mongoose';\nimport { UserDocument } from './entities/user.entity';");

// Replace injection
service = service.replace(/@InjectRepository\(User\)\n\s+private usersRepository: Repository<User>,/g, "@InjectModel(User.name)\n    private userModel: Model<UserDocument>,");

// Replace repository calls
service = service.replace(/this\.usersRepository\.findOne/g, "this.userModel.findOne");
service = service.replace(/this\.usersRepository\.find\(/g, "this.userModel.find(");
service = service.replace(/this\.usersRepository\.create/g, "new this.userModel");

fs.writeFileSync(servicePath, service);

const modulePath = 'backend/src/users/users.module.ts';
let mod = fs.readFileSync(modulePath, 'utf8');
mod = mod.replace(/TypeOrmModule\.forFeature\(\[User\]\)/g, "MongooseModule.forFeature([{ name: User.name, schema: UserSchema }])");
mod = mod.replace(/import \{ TypeOrmModule \} from '@nestjs\/typeorm';/g, "import { MongooseModule } from '@nestjs/mongoose';\nimport { UserSchema } from './entities/user.entity';");
fs.writeFileSync(modulePath, mod);
