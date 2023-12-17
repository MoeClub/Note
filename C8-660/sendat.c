#ifndef _UART_H_
#define _UART_H_
#include <stdio.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>

int serial_init(char *device, int speed, int databits, int parity, int stopbits, int RTSCTS, int newline);
int serial_write(int fd, void *src, int len);
int serial_read(int fd, char *buf, int len);
//串口默认初始化接口
#define serial_default(device, speed) serial_init(device, speed, 8, 'n', 1, 0, 1)
#endif


/**
*@brief  设置串口数据位，停止位和效验位
*@param  fd       类型  int 打开的串口文件句柄
*@param  speed    类型  int 波特率
*@param  databits 类型  int 数据位   取值为 7 或者8
*@param  stopbits 类型  int 停止位   取值为 1 或者2
*@param  parity   类型  char 效验类型 取值为N,E,O,S
*@param  newline  类型  int 新的一行输出
*/
int set_parity(int fd, int speed, int databits, int parity, int stopbits, int RTSCTS, int newline)
{ 
	struct termios options; 
	if  ( tcgetattr(fd, &options)  !=  0) {    
		return -1;  
	}
	
	cfsetispeed(&options, speed);  
	cfsetospeed(&options, speed);
	
	options.c_cflag &= ~CSIZE; 
	
	switch (databits) /*设置数据位数*/
	{   
	case 7:		
		options.c_cflag |= CS7; 
		break;
	case 8:     
		options.c_cflag |= CS8;
		break;   
	default:  
        return -1;  
	}

    options.c_iflag |= INPCK;
    cfmakeraw(&options);
    //options.c_lflag |= (ICANON | ECHO | ECHOE);
    //options.c_lflag &= ~(ICANON | ECHO | ECHOE);
    //options.c_iflag &= ~(IXON | IXOFF);
	switch (parity) 
	{   
		case 'n':
		case 'N':    
			options.c_cflag &= ~PARENB;   /* Clear parity enable */
			options.c_iflag &= ~INPCK;     /* Enable parity checking */ 
			break;  
		case 'o':   
		case 'O':     
			options.c_cflag |= (PARODD | PARENB); /* 设置为奇效验*/  
			break;  
		case 'e':  
		case 'E':   
			options.c_cflag |= PARENB;     /* Enable parity */    
			options.c_cflag &= ~PARODD;   /* 转换为偶效验*/     
			break;
		case 'S': 
		case 's':  /*as no parity*/   
		    options.c_cflag &= ~PARENB;
			options.c_cflag &= ~CSTOPB;
	        break;  
		default: 
			return -1;  
	}  

	/* 设置停止位*/  
	switch (stopbits)
	{   
		case 1:    
			options.c_cflag &= ~CSTOPB;  
			break;  
		case 2:    
			options.c_cflag |= CSTOPB;  
		   break;
		default:    
			 return -1; 
	} 

	/* Set rts/cts */ 
	if (RTSCTS)
	{
		options.c_cflag |= CRTSCTS;
	}
	
	if (newline)
	{
		options.c_lflag |= ICANON;
	}

	tcflush(fd,TCIFLUSH);
	options.c_cc[VTIME] = 150; /* 设置超时15 seconds*/   
	options.c_cc[VMIN] = 0; /* Update the options and do it NOW */
	if (tcsetattr(fd, TCSANOW, &options) != 0)   
	{ 
		return -1;  
	} 
	// printf("set_Parity\n");
	return 0;  
}

/**
*@brief  
*@param  device 串口设备
*@param  speed  串口速度
*@param  databits,parity,stopbits,RTSCTS,分别为数据位,校验位,停止位,rtscts位
*@param  newline 接收数据结尾是否加换行符?
*/
int serial_init(char *device, int speed, int databits, int parity, int stopbits, int RTSCTS, int newline)
{
    int fd, ret;
    fd = open(device, O_RDWR|O_NOCTTY);//O_NONBLOCK 非阻塞, O_WRONLY 只读写, O_RDONLY 只读, O_RDWR 读写,O_NOCTTY 阻塞

	if (-1 == fd) { 
        fprintf(stderr, "ERROR: init %s failed\n", device);
        return -1;
    }

    ret = set_parity(fd, speed, databits, parity, stopbits, RTSCTS, newline);
    if (ret < 0) {
        fprintf(stderr, "ERROR: set parity failed\n");
        return -1;
    }
	
    return fd;
}

/**
*@brief  
*@param  fd   串口端口号文件描述符
*@param  src  需要通过串口发送的数据
*@param  len  需要发送的数据长度
*@param  成功返回0, 否则返回-1
*/
int serial_write(int fd, void *src, int len)
{
    int ret = write(fd, src, len);
    if (len != ret) {
		fprintf(stderr, "ERROR: write serial failed!\n");
		return -1;
    }
    return 0;
}

/**
*@brief  
*@param  fd   串口端口号文件描述符
*@param  src  串口接收数据的指针
*@param  len  需要接收的数据长度
*@param  成功返回0, 否则返回-1
*/
int serial_read(int fd, char *buf, int len)
{
    int ret = read(fd, buf, len-1);
    if (-1 == ret) {
		fprintf(stderr, "ERROR: read serial failed!\n");
		return -1;
    }
    buf[ret] = '\0';
    return ret;
}

static void timeout()
{
	fprintf(stderr, "No response from modem.\n");
	exit(1);
}

/*字符包含判断*/
static int starts_with(const char* prefix, const char* str)
{
	while(*prefix)
	{
		if (*prefix++ != *str++)
		{
			return 0;
		}
	}
	return 1;
}

/*判断是否存在*/
int file_exist(const char* filename)
{
    if (filename && access(filename, F_OK) == 0) {
        return 1;
    }
    return 0;
}

int main(int argc, char **argv)
{
	if(argc != 3)
	{
		fprintf(stderr, "Usage: sendat 2 'ATI'\n");	
		return 1;
	}

	char device[16];
	sprintf(device, "/dev/ttyUSB%s", argv[1]);
	if(file_exist(device)==0)
	{
		fprintf(stderr, "ERROR: AT Device Absent.\n");
   		return 1;
	}
	
	char *message= argv[2];
	if (*message=='\0')
	{
		fprintf(stderr, "ERROR: AT Command Absent.\n");
   		return 1;
	}
	
	signal(SIGALRM, timeout);
	alarm(5);
	
	int bps=1500000;
	char *rn= "\r\n";
	char buff[1024];
	int fd = serial_default(device, bps);
	if(fd < 0) return 1;
	char *msg= strcat(message, rn);
	serial_write(fd, msg, strlen(msg));
	int ret=0;
	while(1) {
		int read = serial_read(fd, buff, sizeof(buff));
		printf("%s", buff);
		
		if(starts_with("OK", buff)) {
			break;
		}
		if(starts_with("ERROR", buff)) {
			ret=1;
			break;
		}
		if(starts_with("COMMAND NOT SUPPORT", buff)) {
			ret=1;
			break;
		}
		if(starts_with("+CME ERROR", buff)) {
			ret=1;
			break;
		}
		if(starts_with("+CMS ERROR", buff)) {
			ret=1;
			break;
		}
	}

	close(fd);
	return ret;
}
