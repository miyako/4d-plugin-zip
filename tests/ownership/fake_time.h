/* Force-included into 4DPlugin-Zip.cpp only: every time(0) call advances a
   synthetic clock by one second so that each progress check fires its
   callback deterministically. */
#ifndef ZIP_HARNESS_FAKE_TIME_H
#define ZIP_HARNESS_FAKE_TIME_H
#include <time.h>
#include <sys/time.h>
#ifdef __cplusplus
#include <ctime>
extern "C"
#endif
time_t zip_harness_time(time_t *t);
#define time(x) zip_harness_time(x)
#endif
