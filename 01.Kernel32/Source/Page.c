#include "Page.h"

//Create Pagetable for IA-32e mode Kernel

void kInitializePageTables( void )
{
	PML4TENTRY* pstPML4TEntry;
	PDPTENTRY* pstPDPTEntry;
	PDENTRY* pstPDEntry;
	DWORD dwMappingAddress;
	int i;

	//Create PML4 Table
	//initialize 0 except first entry
	pstPML4TEntry = ( PML4TENTRY* ) 0x100000;
	kSetPageEntryData( &( pstPML4TEntry[ 0 ] ), 0x00, 0x101000, PAGE_FLAGS_DEFAULT, 0);
	for( i = 1 ; i < PAGE_MAXENTRYCOUNT ; i++ )
	{
		kSetPageEntryData( &( pstPML4TEntry[ i ] ), 0, 0, 0, 0 );
	}

	//create page directory pointer table
	//One PDT can mapping maximum 512GB so, one is enough
	//to set 64 entry and Mapping 64GB
	pstPDPTEntry = ( PDPTENTRY* ) 0x101000;
	for( i = 0 ; i < 64 ; i++ )
	{
		kSetPageEntryData( &( pstPDPTEntry[ i ] ), 0, 0x102000 + (i * PAGE_TABLESIZE ), PAGE_FLAGS_DEFAULT, 0);
	}
	for( i = 64 ; i < PAGE_MAXENTRYCOUNT ; i++ )
	{
		kSetPageEntryData( & (pstPDPTEntry[ i ] ), 0, 0, 0, 0);
	}

	//Create Page directory table
	//one page can Mappinggg maximum 1GB
	//create 64 page so, Can support 64GB
	pstPDEntry = ( PDENTRY* ) 0x102000;
	dwMappingAddress = 0;
	for( i = 0 ; i < PAGE_MAXENTRYCOUNT * 64 ; i++)
	{
		//32bit can't express high address, By Calculating MB and divide Final result 4KB, Calculate address more than 32bit
		kSetPageEntryData( &( pstPDEntry[ i ] ), (i * ( PAGE_DEFAULTSIZE >> 20 ) )  >> 12,
	dwMappingAddress, PAGE_FLAGS_DEFAULT | PAGE_FLAGS_PS, 0 );
		dwMappingAddress += PAGE_DEFAULTSIZE;
	}

}

//Setting Base Address and Attribute Flag to Page Entry
void kSetPageEntryData( PTENTRY* pstEntry, DWORD dwUpperBaseAddress,
		DWORD dwLowerBaseAddress, DWORD dwLowerFlags, DWORD dwUpperFlags )
{
	pstEntry->dwAttributeAndLowerBaseAddress = dwLowerBaseAddress | dwLowerFlags;
	pstEntry->dwUpperBaseAddressAndEXB = ( dwUpperBaseAddress & 0xFF ) | dwUpperFlags;
}


