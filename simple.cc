/*
  Compile:-
  g++ -g3  simple.cc -o /tmp/simple -lpthread -rdynamic;
  Run:
  /tmp/simple
*/
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <cmath>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define THREAD_COUNT 3
#define APP_BLOCK_SIZE 4096
#define LOOP_COUNT 5

int run_io_threads = 0;
int run_cpu_threads = 0;
int busy_cpu_threads = 1;

class C1 {
public:
  int m1;
  int m2;
  int m3;
};
int debug = 0;

pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex2 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex3 = PTHREAD_MUTEX_INITIALIZER;

// Some tools expect this program to exit to produce any
// useful output. Here we exit of user pressing ctrl-c
void sigint_handler(int signal) {
  printf("Terminating due to signal:%d\n", signal);
  exit(0);
}

#include <cmath>
#include <iostream>

#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)

bool isPrime(int x) {
  int limit = std::sqrt(x);
  for (int i = 2; i <= limit; ++i) {
    // if (unlikely(x % i == 0)) {
    if ((x % i == 0)) {
      return false;
    }
  }
  return true;
}

void f1(int c) {
  C1 c1;
  c1.m1 = 1;
  c1.m2 = 2;
  c1.m3 = 3;
  for (int i = 0; i > 0; i++) {
    i = i + 1;
  }
  // printf(".");
  int primeCount = 0;
  //for (int i = 0; i < 1000000000; ++i) {
  for (int i = 0; i < 100; ++i) {
    // if (unlikely(isPrime(i))) {
    if ((isPrime(i))) {
      ++primeCount;
    }
  }
}

void f2(int b) {
  f1(b + 1);
  printf(".");
}
void f3(int a) {
  f2(a + 1);
  printf(".");
}

void f4(int d) {
  f3(d);
  pthread_mutex_lock(&mutex1);
  sleep(1);
  pthread_mutex_unlock(&mutex1);

  pthread_mutex_lock(&mutex2);
  sleep(2);
  pthread_mutex_unlock(&mutex2);

  pthread_mutex_lock(&mutex3);
  sleep(3);
  pthread_mutex_unlock(&mutex3);
  printf(".");
}

#include <time.h>

void *busy_cpu_thread_function(void *vargp) {
  uint32_t my_num = (*(uint32_t *)vargp);
  struct timespec ts;
  char str[100];
  for (int loop_count = 0; loop_count < 2000000000; loop_count++) {
    f1(loop_count);
    sprintf(str, "%d", loop_count);
    ts.tv_sec = 0;
    ts.tv_nsec = 100000 ; // 100 us
    nanosleep(&ts, &ts);
  }
}

void *cpu_thread_function(void *vargp) {
  uint32_t my_num = (*(uint32_t *)vargp);

  for (int loop_count = 0; loop_count < LOOP_COUNT; loop_count++) {
    f4(loop_count);
  }
}

void *io_thread_function(void *vargp) {
  uint32_t my_num = (*(uint32_t *)vargp);
  char file_name[50];

  sprintf(file_name, "/tmp/file.%d", my_num);

  int fd =
      open(file_name, O_CREAT | O_DIRECT | O_SYNC | O_RDWR, S_IRUSR | S_IWUSR);
  if (fd == -1) {
    fd = open(file_name, O_DIRECT | O_SYNC | O_RDWR);
    if (fd == -1) {
      printf("open error %d:%s O_DIRECT|O_SYNC|O_RDWR\n", errno,
             strerror(errno));
      exit(1);
    }
  }

  if (debug) {
    printf("Opened file:%s\n", file_name);
  }

  char *buf;
  int buf_len = APP_BLOCK_SIZE;
  if (posix_memalign((void **)&buf, buf_len /*align*/, buf_len /*size*/)) {
    printf("ERROR posix_memalign:%d %s\n", errno, strerror(errno));
  }

  if (debug) {
    printf("Writing to file:%s\n", file_name);
  }
  for (int loop_count = 0; loop_count < LOOP_COUNT; loop_count++) {
    sleep(1);
    if (debug) {
      printf("pwrite to file:%s\n", file_name);
    }
    memset(buf, loop_count % 10, buf_len);
    int ret = pwrite(fd, buf, buf_len, 0 /* offset*/);
    if (ret == -1) {
      printf("ERROR buf:%s %d:%s\n", buf, errno, strerror(errno));
      exit(2);
    }
    if (debug)
      printf("done pwrite to file:%s\n", file_name);
  }
}

int main(int argc, char **argv) {
  int i;
  pthread_t tid;
  uint32_t io_threads_nums[THREAD_COUNT];
  pthread_t io_threads[THREAD_COUNT];
  pthread_t cpu_threads[THREAD_COUNT];

  signal(SIGINT, sigint_handler);

  for (uint32_t i = 0; i < THREAD_COUNT; i++) {
    io_threads_nums[i] = i;
    if (run_io_threads) {
      pthread_create(&io_threads[i], NULL, io_thread_function,
                     &io_threads_nums[i]);
    }

    if (run_cpu_threads) {
      pthread_create(&cpu_threads[i], NULL, cpu_thread_function,
                     &io_threads_nums[i]);
    }
    if (busy_cpu_threads) {
      pthread_create(&cpu_threads[i], NULL, busy_cpu_thread_function,
                     &io_threads_nums[i]);
    }
    
  }

  if (run_io_threads) {
    printf("io_threads are running ...\n");
  }
  if (run_cpu_threads) {
    printf("cpu_threads are running ...\n");
  }

  for (uint32_t i = 0; run_io_threads && i < THREAD_COUNT; i++) {
    int *return_value;
    pthread_join(io_threads[i], (void **)&return_value);
  }

  for (uint32_t i = 0; run_cpu_threads && i < THREAD_COUNT; i++) {
    int *return_value;
    pthread_join(cpu_threads[i], (void **)&return_value);
  }

  for (uint32_t i = 0; busy_cpu_threads && i < THREAD_COUNT; i++) {
    int *return_value;
    pthread_join(cpu_threads[i], (void **)&return_value);
  }
  
  return 0;
}
