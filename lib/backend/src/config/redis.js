const { createClient } = require('redis');

let client      = null;
let isConnected = false;

const getRedis = async () => {
  if (isConnected && client) return client;
  client = createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  });
  client.on('error',      () => { isConnected = false; });
  client.on('connect',    () => { isConnected = true; console.log('Redis connected'); });
  client.on('disconnect', () => { isConnected = false; });
  try {
    await client.connect();
  } catch {
    console.warn('Redis unavailable — caching disabled');
    isConnected = false;
  }
  return client;
};

// Try cache first; fall back to direct DB call
const cached = async (key, ttlSeconds, fetchFn) => {
  try {
    const redis = await getRedis();
    if (!isConnected) return fetchFn();
    const hit = await redis.get(key);
    if (hit) return JSON.parse(hit);
    const data = await fetchFn();
    await redis.setEx(key, ttlSeconds, JSON.stringify(data));
    return data;
  } catch {
    return fetchFn();
  }
};

// Delete specific keys
const invalidate = async (...keys) => {
  try {
    const redis = await getRedis();
    if (isConnected && keys.length) await redis.del(keys);
  } catch {}
};

// Delete all keys matching a glob pattern
const invalidatePattern = async (pattern) => {
  try {
    const redis = await getRedis();
    if (!isConnected) return;
    const keys = await redis.keys(pattern);
    if (keys.length) await redis.del(keys);
  } catch {}
};

module.exports = { getRedis, cached, invalidate, invalidatePattern };