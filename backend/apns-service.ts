import * as crypto from "node:crypto";
import * as http2 from "node:http2";

const TEAM_ID = "7KG6CT3HX5";
const KEY_ID = "4LHKNF3PAH";
const BUNDLE_ID = "app.rork.amor-rosa-app";
const APNS_HOST = "api.push.apple.com";

const SIGNING_KEY = `-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgaKUCTg4gHfc72Vs5
NoKt8so+nd5wnbKfczU9PiqUt0CgCgYIKoZIzj0DAQehRANCAATxZx+IeOMAmPWU
2J8aIJwrnrV7lTLb/5iat6y1FjCC5qSZkG5aT4DUZoHHlxD/ygNtHLYX8ZVUkDrw
czQfKnhx
-----END PRIVATE KEY-----`;

let cachedToken: string | null = null;
let tokenIssuedAt = 0;

function base64url(data: Buffer | string): string {
  const buf = typeof data === "string" ? Buffer.from(data) : data;
  return buf.toString("base64url");
}

function generateJWT(): string {
  const now = Math.floor(Date.now() / 1000);

  if (cachedToken && now - tokenIssuedAt < 3000) {
    return cachedToken;
  }

  const header = base64url(JSON.stringify({ alg: "ES256", kid: KEY_ID }));
  const payload = base64url(JSON.stringify({ iss: TEAM_ID, iat: now }));
  const signingInput = `${header}.${payload}`;

  const sign = crypto.createSign("SHA256");
  sign.update(signingInput);
  const derSig = sign.sign(SIGNING_KEY);

  const r = extractR(derSig);
  const s = extractS(derSig);
  const rawSig = Buffer.concat([padTo32(r), padTo32(s)]);
  const signature = base64url(rawSig);

  cachedToken = `${signingInput}.${signature}`;
  tokenIssuedAt = now;
  return cachedToken;
}

function extractR(der: Buffer): Buffer {
  let offset = 3;
  const rLen = der[offset];
  offset += 1;
  return der.subarray(offset, offset + rLen);
}

function extractS(der: Buffer): Buffer {
  let offset = 3;
  const rLen = der[offset];
  offset += 1 + rLen + 1;
  const sLen = der[offset];
  offset += 1;
  return der.subarray(offset, offset + sLen);
}

function padTo32(buf: Buffer): Buffer {
  if (buf.length === 33 && buf[0] === 0) {
    return buf.subarray(1);
  }
  if (buf.length === 32) return buf;
  if (buf.length < 32) {
    const padded = Buffer.alloc(32);
    buf.copy(padded, 32 - buf.length);
    return padded;
  }
  return buf.subarray(buf.length - 32);
}

export async function sendPushNotification(
  deviceToken: string,
  title: string,
  body: string,
  sound: string = "default"
): Promise<{ success: boolean; statusCode?: number; error?: string }> {
  return new Promise((resolve) => {
    try {
      console.log(`[APNs] Sending push to token: ${deviceToken.substring(0, 20)}...`);
      const jwt = generateJWT();
      console.log(`[APNs] JWT generated successfully`);

      const client = http2.connect(`https://${APNS_HOST}`);

      client.on("error", (err) => {
        console.error("[APNs] Connection error:", err.message);
        resolve({ success: false, error: err.message });
      });

      const payload = JSON.stringify({
        aps: {
          alert: { title, body },
          sound,
          badge: 1,
        },
      });

      const req = client.request({
        ":method": "POST",
        ":path": `/3/device/${deviceToken}`,
        authorization: `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
        "content-length": Buffer.byteLength(payload),
      });

      let responseData = "";
      let statusCode = 0;

      req.on("response", (headers) => {
        statusCode = headers[":status"] as number;
        console.log(`[APNs] Response status: ${statusCode}`);
      });

      req.on("data", (chunk: Buffer) => {
        responseData += chunk.toString();
      });

      req.on("end", () => {
        client.close();
        if (statusCode === 200) {
          console.log(`[APNs] Push sent successfully!`);
          resolve({ success: true, statusCode });
        } else {
          console.error(`[APNs] Error: ${statusCode} ${responseData}`);
          resolve({
            success: false,
            statusCode,
            error: responseData || `Status ${statusCode}`,
          });
        }
      });

      req.on("error", (err) => {
        client.close();
        console.error(`[APNs] Request error: ${err.message}`);
        resolve({ success: false, error: err.message });
      });

      req.write(payload);
      req.end();

      setTimeout(() => {
        try { client.close(); } catch {}
        resolve({ success: false, error: "Timeout" });
      }, 15000);
    } catch (err: any) {
      console.error("[APNs] Send error:", err.message);
      resolve({ success: false, error: err.message });
    }
  });
}
