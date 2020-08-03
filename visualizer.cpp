#include <irrlicht/irrlicht.h>
#include <stdio.h>
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
	IrrlichtDevice* device = createDevice(video::EDT_OPENGL, core::dimension2d<u32>(640, 480), 16, false, true, false, &receiver);

	video::IVideoDriver* driver = device->getVideoDriver();
	scene::ISceneManager* smgr = device->getSceneManager();
	
	// Setup drone

	scene::ISceneNode *yawNode = smgr->addEmptySceneNode();
	scene::ISceneNode *pitchNode = smgr->addEmptySceneNode(yawNode);
	scene::ISceneNode *rowNode = smgr->addEmptySceneNode(pitchNode);
	scene::IAnimatedMeshSceneNode* drone = smgr->addAnimatedMeshSceneNode(smgr->getMesh("drone.obj"),rowNode);

	yawNode->setPosition(core::vector3df(0,0,0));
	drone->setRotation(core::vector3df(0,90,0));
	drone->setScale(core::vector3df(0.01,0.01,0.01));
	drone->setMaterialFlag(video::EMF_NORMALIZE_NORMALS, true);
	drone->addShadowVolumeSceneNode();

	// Setup light

	smgr->addLightSceneNode(0,core::vector3df(0,10,0));

	// Setup camera

	scene::ICameraSceneNode* camera = smgr->addCameraSceneNode();

	camera->setPosition(core::vector3df(0.2,0.6,0));
	camera->setTarget(core::vector3df(0.0,0.5,0.0));
	camera->setFarValue(2000.0f);
	camera->setNearValue(0.01f);

	// Setup terrain

	scene::ITerrainSceneNode* terrain = smgr->addTerrainSceneNode(
		"../../irrlicht-1.8.4/media/terrain-heightmap.bmp",
		0,					// parent node
		-1,					// node id
		core::vector3df(-5.0, 0.0, -5.0),		// position
		core::vector3df(0.f, 0.f, 0.f),		// rotation
		core::vector3df(10.0 / 256.0, 0.25 / 256.0, 10.0 / 256.0),	// scale
		video::SColor ( 255, 255, 255, 255 ),	// vertexColor
		5,					// maxLOD
		scene::ETPS_17,				// patchSize
		4					// smoothFactor
		);

	terrain->setMaterialTexture(0, driver->getTexture("../../irrlicht-1.8.4/media/terrain-texture.jpg"));
	terrain->setMaterialTexture(1, driver->getTexture("../../irrlicht-1.8.4/media/detailmap3.jpg"));
	terrain->setMaterialType(video::EMT_DETAIL_MAP);
	terrain->scaleTexture(1.0f, 4.0f);
	
	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, false);

	// Setup skydome

	scene::ISceneNode* skydome=smgr->addSkyDomeSceneNode(driver->getTexture("../../irrlicht-1.8.4/media/skydome.jpg"),16,8,0.8f,2.0f);
	skydome->setVisible(true);

	driver->setTextureCreationFlag(video::ETCF_CREATE_MIP_MAPS, true);
	
	device->setWindowCaption(L"Drone visualization");
	
	const f32 MOVEMENT_SPEED = .1f;


	while(device->run())
	{
		const u32 t0 = device->getTimer()->getTime();
		/*const f32 frameDeltaTime = (f32)(now - then) / 1000.f; // Time in seconds
		then = now;

		core::vector3df nodePosition = drone->getPosition();

		if(receiver.IsKeyDown(irr::KEY_KEY_W))
			nodePosition.Y += MOVEMENT_SPEED * frameDeltaTime;
		else if(receiver.IsKeyDown(irr::KEY_KEY_S))
			nodePosition.Y -= MOVEMENT_SPEED * frameDeltaTime;

		if(receiver.IsKeyDown(irr::KEY_KEY_A))
			nodePosition.X -= MOVEMENT_SPEED * frameDeltaTime;
		else if(receiver.IsKeyDown(irr::KEY_KEY_D))
			nodePosition.X += MOVEMENT_SPEED * frameDeltaTime;

		drone->setPosition(nodePosition);
*/
		float x,y,z,phi,theta,psi;
		if (scanf("%f,%f,%f,%f,%f,%f\n",&x,&y,&z,&phi,&theta,&psi) > 0)
		{
			yawNode->setPosition(core::vector3df(x,-z,y));
			yawNode->setRotation(core::vector3df(0.0,-psi * 180.0 / 3.1416,0.0));
			pitchNode->setRotation(core::vector3df(0.0,0.0,theta * 180.0 / 3.1416));
			rowNode->setRotation(core::vector3df(phi * 180.0 / 3.1416,0.0,0.0));
	
			camera->setTarget(yawNode->getPosition());
			camera->setPosition(yawNode->getPosition() + core::vector3df(0.1,0.1,0.0));
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

