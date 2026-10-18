#include "ClientLayer.h"

#include "Walnut/Core/Log.h"
#include "Walnut/ImGui/ImGuiTheme.h"
#include "Walnut/Input/KeyCodes.h"
#include "glm/geometric.hpp"

#include "imgui.h"
#include "imgui_internal.h"
#include "misc/cpp/imgui_stdlib.h"

#include "Walnut/Input/Input.h"
#include "Walnut/Serialization/BufferStream.h"

#include "ServerPacket.h"

#include <cstdint>

namespace Cubed
{
    
    static Walnut::Buffer s_ScratchBuffer;

    static void DrawRect(glm::vec2 position, glm::vec2 size, uint32_t color = 0xffff00ff)
    {
        ImGuiViewport* viewport = ImGui::GetMainViewport();
        ImDrawList* drawList = ImGui::GetBackgroundDrawList(viewport);

        ImVec2 min = viewport->Pos + ImVec2(position.x, position.y);
        ImVec2 max = min + ImVec2(size.x, size.y);

        drawList->AddRectFilled(min, max, color);
    }

    void ClientLayer::OnAttach()
    {
        s_ScratchBuffer.Allocate(10 * 1024 * 1024);

        m_Client.SetDataReceivedCallback([this](const Walnut::Buffer buffer) { OnDataReceived(buffer); });
    }

    void ClientLayer::OnDetach()
    {

    }

    void ClientLayer::OnUpdate(float ts)
    {
        if (m_Client.GetConnectionStatus() != Walnut::Client::ConnectionStatus::Connected)
            return;

        glm::vec2 dir{ 0.0f, 0.0f };

        if (Walnut::Input::IsKeyDown(Walnut::KeyCode::W))
            dir.y = -1.0f;
        else if (Walnut::Input::IsKeyDown(Walnut::KeyCode::S))
            dir.y = 1.0f;

        if (Walnut::Input::IsKeyDown(Walnut::KeyCode::A))
            dir.x = -1.0f;
        else if (Walnut::Input::IsKeyDown(Walnut::KeyCode::D))
            dir.x = 1.0f;

        if (glm::length(dir) > 0.0f)
        {
            //dir = glm::normalize(dir); (Optional for gameplay reasons)
            
            const float speed = 150.0f;
            m_PlayerVelocity = dir * speed;
        }

        m_PlayerPosition += m_PlayerVelocity * ts;
        
        m_PlayerVelocity = glm::mix(m_PlayerVelocity, glm::vec2(0.0f), 5.0f * ts);

        Walnut::BufferStreamWriter stream(s_ScratchBuffer);
        stream.WriteRaw<PacketType>(PacketType::ClientUpdate);
        stream.WriteRaw<glm::vec2>(m_PlayerPosition);
        stream.WriteRaw<glm::vec2>(m_PlayerVelocity);

        m_Client.SendBuffer(stream.GetBuffer());
    }

    void ClientLayer::OnUIRender()
    {
        Walnut::Client::ConnectionStatus connectionStatus = m_Client.GetConnectionStatus();
        if (connectionStatus == Walnut::Client::ConnectionStatus::Connected)
        {
            // Play Game
            DrawRect(m_PlayerPosition, { 50, 50 }, 0xffff00ff);

            m_PlayerDataMutex.lock();
            std::map<uint32_t, PlayerData> playerData = m_PlayerData;
            m_PlayerDataMutex.unlock();

            for (const auto& [id, data]: playerData)
            {
                if (id == m_PlayerID)
                    continue;

                DrawRect(data.Position, { 50, 50 }, 0xff00ff00);
            }
        }
        else
        {
            ImGui::Begin("Connect to server");

            ImGui::InputText("Server adress", &m_ServerAddress);
            if (connectionStatus == Walnut::Client::ConnectionStatus::FailedToConnect)
                ImGui::TextColored(ImColor(Walnut::UI::Colors::Theme::error), "Failed to Connect.");
            else if (connectionStatus == Walnut::Client::ConnectionStatus::Connecting)
                ImGui::TextColored(ImColor(Walnut::UI::Colors::Theme::textDarker), "Connecting...");
            if (ImGui::Button("Connect"))
            {
                m_Client.ConnectToServer(m_ServerAddress);
            }

            ImGui::End();
        }
    }

    void ClientLayer::OnDataReceived(const Walnut::Buffer buffer)
    {
        Walnut::BufferStreamReader stream(buffer);
        
        PacketType type;
        stream.ReadRaw<PacketType>(type);

        switch (type)
        {
        case PacketType::ClientConnect:
            uint32_t idFromServer;
            stream.ReadRaw(idFromServer);
            m_PlayerID = idFromServer;
            break;
        case PacketType::ClientUpdate:
            // list of other clients
            m_PlayerDataMutex.lock();
            stream.ReadMap(m_PlayerData);
            m_PlayerDataMutex.unlock();

            break;
        }
    }

}