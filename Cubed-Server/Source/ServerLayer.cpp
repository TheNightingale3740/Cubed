#include "ServerLayer.h"
#include "ServerPacket.h"

#include "Walnut/Core/Log.h"
#include "Walnut/Serialization/BufferStream.h"

#include <chrono>
#include <thread>

namespace Cubed
{

    static Walnut::Buffer s_ScratchBuffer;

    void ServerLayer::OnAttach()
    {
        s_ScratchBuffer.Allocate(10 * 1024 * 1024); // 10MB

        m_Console.SetMessageSendCallback([this](std::string_view message) { OnConsoleMessage(message); });

        m_Server.SetClientConnectedCallback([this](const Walnut::ClientInfo& clientInfo) { OnClientConnected(clientInfo); });
        m_Server.SetClientDisconnectedCallback([this](const Walnut::ClientInfo& clientInfo) { OnClientDisconnected(clientInfo); });
        m_Server.SetDataReceivedCallback([this](const Walnut::ClientInfo& clientInfo, const Walnut::Buffer buffer) { OnDataReceived(clientInfo, buffer); });

        m_Server.Start();
    }

    void ServerLayer::OnDetach()
    {
        s_ScratchBuffer.Release();
        m_Server.Stop();
    }

    void ServerLayer::OnUpdate(float ts)
    {
        Walnut::Buffer buffer;
        buffer.Allocate(1024 * 1024);
        Walnut::BufferStreamWriter stream(buffer);

        m_PlayerDataMutex.lock();
        {
            stream.WriteRaw(PacketType::ClientUpdate);
            stream.WriteMap(m_PlayerData);
        }
        m_PlayerDataMutex.unlock();

        m_Server.SendBufferToAllClients(stream.GetBuffer());

        buffer.Release();

        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }

    void ServerLayer::OnConsoleMessage(std::string_view message)
    {
        if (message.starts_with('/'))
        {
            // command
            std::cout << "You called the " << message << " command!";
        }
    }

    void ServerLayer::OnClientConnected(const Walnut::ClientInfo& clientInfo)
    {
        WL_INFO_TAG("Server", "Client connected! ID={}", clientInfo.ID);

        Walnut::BufferStreamWriter stream(s_ScratchBuffer);
        stream.WriteRaw(PacketType::ClientConnect);
        stream.WriteRaw(clientInfo.ID);

        m_Server.SendBufferToClient(clientInfo.ID, stream.GetBuffer()); 
    }

    void ServerLayer::OnClientDisconnected(const Walnut::ClientInfo& clientInfo)
    {
        WL_INFO_TAG("Server", "Client disconnected! ID={}", clientInfo.ID);
    }

    void ServerLayer::OnDataReceived(const Walnut::ClientInfo& clientInfo, const Walnut::Buffer buffer)
    {
        Walnut::BufferStreamReader stream(buffer);
        PacketType type;
        stream.ReadRaw<PacketType>(type);

        switch (type)
        {
        case PacketType::ClientUpdate:
            m_PlayerDataMutex.lock();
            {
                PlayerData& playerData = m_PlayerData[clientInfo.ID];
                stream.ReadRaw<glm::vec2>(playerData.Position);
                stream.ReadRaw<glm::vec2>(playerData.Velocity);
            }
            m_PlayerDataMutex.unlock();
            break;
        }
    }

}