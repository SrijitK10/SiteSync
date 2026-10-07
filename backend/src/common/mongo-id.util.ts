import { Types } from 'mongoose';

export function buildIdFilter(id: string): Record<string, any> {
  if (!id) return { _id: null };
  const strId = String(id).trim();
  if (Types.ObjectId.isValid(strId)) {
    return {
      $or: [
        { id: strId },
        { _id: new Types.ObjectId(strId) },
      ],
    };
  }
  return { id: strId };
}

export function buildIdsFilter(ids: string[]): Record<string, any> {
  if (!ids || !ids.length) return { id: { $in: [] } };
  const cleanIds = ids.map(id => String(id).trim()).filter(Boolean);
  const validObjectIds = cleanIds
    .filter(id => Types.ObjectId.isValid(id))
    .map(id => new Types.ObjectId(id));

  if (validObjectIds.length > 0) {
    return {
      $or: [
        { id: { $in: cleanIds } },
        { _id: { $in: validObjectIds } },
      ],
    };
  }
  return { id: { $in: cleanIds } };
}

export function toCleanObject<T = any>(doc: any): T {
  if (!doc) return doc;
  const obj = typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
  if (!obj.id && obj._id) {
    obj.id = obj._id.toString();
  }
  delete obj.__v;
  return obj as T;
}

export function toCleanObjects<T = any>(docs: any[]): T[] {
  if (!Array.isArray(docs)) return [];
  return docs.map(d => toCleanObject<T>(d));
}
