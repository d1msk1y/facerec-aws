// Domain Entities
/*
Author: Dmytro Yatsenko, Julian Saxer
Date: 2025-12-19
Version: 1.0
*/

export interface RecognitionResult {
    Name: string;
    MatchConfidence: number;
}

// Domain Interfaces (Ports)
export interface IImageStorageService {
    retrieveImage(bucket: string, key: string): Promise<Buffer | Uint8Array>;
    saveResult(bucket: string, key: string, data: RecognitionResult): Promise<void>;
}

export interface IRecognitionService {
    recognizeCelebrity(imageBytes: Buffer | Uint8Array): Promise<RecognitionResult | null>;
}
