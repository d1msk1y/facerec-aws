/*
Author: Dmytro Yatsenko, Julian Saxer
Date: 2025-12-19
Version: 1.0
*/

import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { Readable } from "stream";
import type { IImageStorageService, RecognitionResult } from "../domain/types";

class S3Adapter implements IImageStorageService {
    private client: S3Client;

    constructor(region: string) {
        this.client = new S3Client({ region });
    }

    async retrieveImage(bucket: string, key: string): Promise<Buffer> {
        const command = new GetObjectCommand({ Bucket: bucket, Key: key });
        const response = await this.client.send(command);

        if (!response.Body) {
            throw new Error(`Empty body for object ${key} in bucket ${bucket}`);
        }

        return this.streamToBuffer(response.Body as Readable);
    }

    async saveResult(bucket: string, key: string, data: RecognitionResult): Promise<void> {
        const command = new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: JSON.stringify(data, null, 2),
            ContentType: "application/json"
        });
        await this.client.send(command);
    }

    private async streamToBuffer(stream: Readable): Promise<Buffer> {
        return new Promise((resolve, reject) => {
            const chunks: any[] = [];
            stream.on("data", (chunk) => chunks.push(chunk));
            stream.on("error", reject);
            stream.on("end", () => resolve(Buffer.concat(chunks)));
        });
    }
}

export default S3Adapter;