#include "Walnut/ApplicationGUI.h"
#include "Walnut/EntryPoint.h"

#include "ClientLayer.h"

Walnut::Application* Walnut::CreateApplication(int argc, char** argv)
{
	Walnut::ApplicationSpecification spec;
	spec.Name = "Cubed";
	spec.Width = 1280;
	spec.Height = 720;
	spec.CustomTitlebar = false;
	spec.UseDockspace = false;

	Walnut::Application* app = new Walnut::Application(spec);
	app->PushLayer<Cubed::ClientLayer>();
	return app;
}