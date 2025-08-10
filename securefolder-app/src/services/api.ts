import axios from 'axios';
import { getIdToken } from './auth';

const BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL || 'http://localhost:4000';

const client = axios.create({ baseURL: BASE_URL });

client.interceptors.request.use(async (config) => {
  const token = await getIdToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export const api = client;