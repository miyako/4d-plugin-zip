#include "4DPluginAPI.h"

#define CMD_DELAY_PROCESS 323
#define CMD_Current_process 322
#define CMD_Process_aborted 672
#define CMD_IDLE 311

/*
 these are placeholders for plugin api calls that are not threadsafe
 they may or may not work...
 */

bool PA_IsProcessDying2();
PA_long32 PA_GetCurrentProcessNumber2();
void PA_PutProcessToSleep2(PA_long32 process, double delay);