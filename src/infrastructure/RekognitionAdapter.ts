import { RekognitionClient, RecognizeCelebritiesCommand } from "@aws-sdk/client-rekognition";
import type { IRecognitionService, RecognitionResult } from "../domain/types";

export class RekognitionAdapter implements IRecognitionService {
    private client: RekognitionClient;

    constructor(region: string) {
        this.client = new RekognitionClient({ region });
    }

    async recognizeCelebrity(imageBytes: Buffer): Promise<RecognitionResult | null> {
        const command = new RecognizeCelebritiesCommand({
            Image: { Bytes: imageBytes }
        });

        const response = await this.client.send(command);

        if (response.CelebrityFaces && response.CelebrityFaces.length > 0) {
            // Get the match with the highest confidence
            const topMatch = response.CelebrityFaces.reduce((prev: any, current: any) =>
                (prev.MatchConfidence ?? 0) > (current.MatchConfidence ?? 0) ? prev : current
            );

            return {
                Name: topMatch.Name || "Unknown",
                MatchConfidence: topMatch.MatchConfidence || 0
            };
        }

        return null;
    }
}
