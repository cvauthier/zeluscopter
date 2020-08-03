#include <irrlicht/irrlicht.h>
#include <cstdio>
#include <cmath>
#include <unistd.h>
#include <fcntl.h>

using namespace irr;

class MyEventReceiver : public IEventReceiver
{
public:
	
	virtual bool OnEvent(const SEvent& event)
	{
		if (event.EventType == irr::EET_KEY_INPUT_EVENT)
			KeyIsDown[event.KeyInput.Key] = event.KeyInput.PressedDown;

		return false;
	}

	virtual bool IsKeyDown(EKEY_CODE keyCode) const
	{
		return KeyIsDown[keyCode];
	}
	
	MyEventReceiver()
	{
		for (u32 i=0; i<KEY_KEY_CODES_COUNT; ++i)
			KeyIsDown[i] = false;
	}

private:
		
	bool KeyIsDown[KEY_KEY_CODES_COUNT];
};

int main(int argc, char **argv)
{
	fcntl(1,F_SETFL,O_NONBLOCK);

	MyEventReceiver receiver;
	
	SIrrlichtCreationParameters params;
	params.DriverType = video::EDT_OPENGL;
	params.WindowSize = core::dimension2d<u32>(640,480);
	params.EventReceiver = &receiver;
	params.LoggingLevel = ELL_ERROR;
	params.Stencilbuffer = true;
	
	IrrlichtDevice* device = createDeviceEx(params);

	video::IVideoDriver* driver = device->getVideoDriver();
	scene::ISceneManager* smgr = device->getSceneManager();

	// Setup light

	smgr->addLightSceneNode(0,core::vector3df(0,10,0));
	
	// Setup drone

	scene::ISceneNode *yawNode = smgr->addEmptySceneNode();
	scene::ISceneNode *pitchNode = smgr->addEmptySceneNode(yawNode);
	scene::ISceneNode *rowNode = smgr->addEmptySceneNode(pitchNode);
	scene::IAnimatedMeshSceneNode* drone = smgr->addAnimatedMeshSceneNode(smgr->getMesh("media/drone.obj"),rowNode);

	yawNode->setPosition(core::vector3df(0.0,0.5,0.0));
	drone->setRotation(core::vector3df(0,90,0));
	drone->setScale(core::vector3df(0.01,0.01,0.01));
	drone->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	drone->addShadowVolumeSceneNode();

	// Setup camera

	scene::ICameraSceneNode* camera = smgr->addCameraSceneNode();

	camera->setPosition(core::vector3df(0.2,0.6,0));
	camera->setTarget(core::vector3df(0.0,0.5,0.0));
	camera->setFarValue(2000.0f);
	camera->setNearValue(0.01f);

	// Setup terrain

	scene::ITerrainSceneNode* terrain = smgr->addTerrainSceneNode("media/hmap.png", 0, -1,
		core::vector3df(-5.0, 0.0, -5.0),		// position
		core::vector3df(0.f, 0.f, 0.f),		// rotation
		core::vector3df(10.0 / 256.0, 0.25 / 256.0, 10.0 / 256.0),	// scale
		video::SColor ( 255, 255, 255, 255 ),	// vertexColor
		5, scene::ETPS_17,	4);

	terrain->setMaterialTexture(0, driver->getTexture("media/grass.jpg"));
	terrain->setMaterialType(video::EMT_SOLID);
	terrain->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	terrain->scaleTexture(10.0f);
	
	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, false);

	// Setup skydome

	scene::ISceneNode* skydome=smgr->addSkyDomeSceneNode(driver->getTexture("media/sky.jpg"),16,8,0.8f,2.0f);
	skydome->setVisible(true);

	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, true);
	
	device->setWindowCaption(L"Drone visualization");
	
	double cam_theta = 0.0;
	double cam_phi = 3.1416 / 4.0;
	double cam_l = 0.2;

	while(device->run())
	{
		const u32 t0 = device->getTimer()->getTime();

		if(receiver.IsKeyDown(irr::KEY_UP))
			cam_phi = fmin(fmax(cam_phi+0.01,-1.5),1.5);
		else if(receiver.IsKeyDown(irr::KEY_DOWN))
			cam_phi = fmin(fmax(cam_phi-0.01,-1.5),1.5);
		
		if(receiver.IsKeyDown(irr::KEY_KEY_W))
			cam_l = fmin(fmax(cam_l+0.002,0.06),1.0);
		else if(receiver.IsKeyDown(irr::KEY_KEY_S))
			cam_l = fmin(fmax(cam_l-0.002,0.06),1.0);

		if(receiver.IsKeyDown(irr::KEY_RIGHT))
			cam_theta += 0.02;
		else if(receiver.IsKeyDown(irr::KEY_LEFT))
			cam_theta -= 0.02;

		float x,y,z,phi,theta,psi;
		if (scanf("%f,%f,%f,%f,%f,%f\n",&x,&y,&z,&phi,&theta,&psi) > 0)
		{
			yawNode->setPosition(core::vector3df(x,-z,y));
			yawNode->setRotation(core::vector3df(0.0,-psi * 180.0 / 3.1416,0.0));
			pitchNode->setRotation(core::vector3df(0.0,0.0,theta * 180.0 / 3.1416));
			rowNode->setRotation(core::vector3df(phi * 180.0 / 3.1416,0.0,0.0));
	
			camera->setTarget(yawNode->getPosition());
			core::vector3df vec(cam_l*cos(cam_theta)*cos(cam_phi),
													cam_l*sin(cam_phi),
													cam_l*sin(cam_theta)*cos(cam_phi));
			camera->setPosition(yawNode->getPosition() + vec);
		}

		driver->beginScene(true, true, video::SColor(255,113,113,133));
		smgr->drawAll();
		driver->endScene();

		core::stringw tmp(L"Drone visualisation - fps:");
		tmp += driver->getFPS();
		device->setWindowCaption(tmp.c_str());

		const u32 t1 = device->getTimer()->getTime();
		if (t1 < t0+20)
			device->sleep(20+t0-t1);
	}

	device->drop();
	
	return 0;
}

