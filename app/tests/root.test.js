const request = require('supertest');
const app = require('../src/app');

describe('Root endpoint', () => {
  it('identifies the service', async () => {
    const res = await request(app).get('/');

    expect(res.statusCode).toBe(200);
    expect(res.body.service).toBe('gitops-app');
  });
});
