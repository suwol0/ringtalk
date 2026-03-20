-- AlterTable
ALTER TABLE "messages" ADD COLUMN "clientMessageId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "messages_roomId_senderId_clientMessageId_key" ON "messages"("roomId", "senderId", "clientMessageId");
