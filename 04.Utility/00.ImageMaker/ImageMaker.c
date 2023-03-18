#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
//#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

// https://m.blog.naver.com/PostView.naver?isHttpsRedirect=true&blogId=komixer_die&logNo=30150856004
#ifndef O_BINARY
#define O_BINARY 0
#endif

#define BYTESOFSECTOR	512




//define function

int AdjustInSectorSize( int iFd, int iSourceSize );
void WriteKernelInformation( int iTargetFd, int iTotalKernelSectorCount
		,int iKernel32SectorCount );
int CopyFile( int iSourceFd, int iTargerFd );


//Main
int main(int argc, char* argv[])
{
	int iSourceFd;
	int iTargetFd;
	int iBootLoaderSize;
	int iKernel32SectorCount;
	int iKernel64SectorCount;
	int iSourceSize;

	//Check Command line option
	if( argc < 4 )
	{
		fprintf( stderr, "[Error] ImageMaker.exe BootLoader.bin Kernel32.bin Kernel64.bin\n");
		exit( -1 );
	}

	//Create Disk.image file
	if( ( iTargetFd = open( "Disk.img", O_RDWR | O_CREAT | O_TRUNC |
			O_BINARY, S_IREAD | S_IWRITE ) ) ==-1 )
	{
		fprintf( stderr , "[ERROR] Disk.img open fail.\n");
		exit( -1 );
	}

	//------------------------------
	// Copy all to open the BootLoader file to Disk img file

	//------------------------------
	printf( "[INFO] Copy boot loader to image file\n ");
	if( ( iSourceFd = open( argv[ 1 ], O_RDONLY | O_BINARY ) ) == -1 ){
		fprintf( stderr, "[ERROR] %s open fail\n", argv [ 1 ] );
		exit(-1);
	}

	iSourceSize = CopyFile( iSourceFd, iTargetFd );
	close( iSourceFd );

	//to make file size to 512byte(Sector size) full remain part to 0x00
	iBootLoaderSize = AdjustInSectorSize( iTargetFd, iSourceSize);
	printf( "[INFO] %s size = [%d] and sector count = [%d]\n", argv[ 1 ], iSourceSize, iBootLoaderSize );


	//------------------------------
	//Copy all to open the 32bit kernel file to Disk img file
	//------------------------------

	printf( "[INFO] Copy protected mode kernel to image file\n" );

	if( ( iSourceFd = open( argv[ 2 ], O_RDONLY | O_BINARY ) ) == -1 )
	{
		fprintf( stderr, "[Error] %s open fail\n", argv[ 2 ] );
		exit( -1 );
	}

	iSourceSize = CopyFile( iSourceFd, iTargetFd );
	close( iSourceFd );

	//to make file size to 512byte(Sector size) full remain part to 0x00
	iKernel32SectorCount = AdjustInSectorSize( iTargetFd, iSourceSize );
	printf( "[INFO] %s size = [%d] and sector count = [%d]\n", argv[ 2 ], iSourceSize, iKernel32SectorCount );

	//---------------------------------------------------------------------
	//Copy all opening 64bit kernel file to disk.img
	//---------------------------------------------------------------------
	printf( "[INFO] Copy IA-32e mode kernel to image file\n" );
	if( ( iSourceFd = open( argv[ 3 ], O_RDONLY | O_BINARY ) ) == -1 )
	{
		fprintf( stderr, "[ERROR] %s open fail\n", argv[ 3 ] );
		exit( -1 );
	}

	iSourceSize = CopyFile( iSourceFd, iTargetFd );
	close( iSourceFd );

	iKernel64SectorCount = AdjustInSectorSize( iTargetFd, iSourceSize );
	printf( "[INFO] %s size = [%d] and sector count = [%d]\n", argv[ 3 ], iSourceSize,
			iKernel64SectorCount );

	//------------------------------
	//reload Kernel information to disk img
	//------------------------------
	printf( "[INFO] Start to Write Kernel Information\n" );
	//Input Information of Kernel at 5th byte of Boot Sector
	WriteKernelInformation( iTargetFd, iKernel32SectorCount + iKernel64SectorCount, iKernel32SectorCount );
	printf( "[INFO] Image file create complete\n" );

	close( iTargetFd);
	return 0;
}

//full of 0x00 from now location to 512 drainage
int AdjustInSectorSize( int iFd, int iSourceSize )
{
	int i;
	int iAdjustSizeToSector;
	int iSectorCount;
	char cCh;

	iAdjustSizeToSector = iSourceSize % BYTESOFSECTOR;
	cCh = 0x00;

	if( iAdjustSizeToSector != 0 )
	{
		iAdjustSizeToSector = 512 - iAdjustSizeToSector;
		printf( "[INFO] File size [%lu] and fill [%u] byte\n", iSourceSize, iAdjustSizeToSector );
		for( i = 0 ; i < iAdjustSizeToSector ; i++ )
		{
			write( iFd , &cCh , 1 );
		}
	}
	else
	{
		printf( ":[INFO] File size is aligned 512 byte\n");
	}

	iSectorCount = (iSourceSize + iAdjustSizeToSector ) / BYTESOFSECTOR;
	return iSectorCount;
}

//input Kernel Information to BootLoader
void WriteKernelInformation( int iTargetFd, int iTotalKernelSectorCount,
		int iKernel32SectorCount )
{
	unsigned short usData;
	long lPosition;

	// Location 5byte far from start of file Show all Information Sector of Kernel
	lPosition = lseek( iTargetFd, (off_t)5, SEEK_SET );
	if( lPosition == -1 )
	{
		fprintf( stderr, "lseek fail. Return value = %d, errno = %d, %d\n", lPosition, errno, SEEK_SET );
		exit( -1 );
	}

	usData = ( unsigned short ) iTotalKernelSectorCount;
	write( iTargetFd, &usData, 2 );
	usData = ( unsigned short ) iKernel32SectorCount;
	write( iTargetFd, &usData, 2 );

	printf( "[INFO] Total sector count except boot loader [%d]\n", iTotalKernelSectorCount );
	printf( "[INFO] Total sector count of protected mode kernel [%d]\n", iKernel32SectorCount );
}

//Copy Source FD to Target FD and Return that Size
int CopyFile( int iSourceFd, int iTargetFd )
{
	int iSourceFileSize;
	int iRead;
	int iWrite;
	char vcBuffer[ BYTESOFSECTOR ];

	iSourceFileSize = 0;
	while ( 1 )
	{
		iRead = read( iSourceFd, vcBuffer, sizeof( vcBuffer ) );
		iWrite = write( iTargetFd, vcBuffer, iRead );

		if( iRead != iWrite )
		{
			fprintf( stderr, "[ERROR] iRead != iWrite.. \n" );
			exit(-1);
		}
		iSourceFileSize += iRead;

		if( iRead != sizeof( vcBuffer ) )
		{
			break;
		}
	}
	return iSourceFileSize;
}


