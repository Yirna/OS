#ifndef __PAGE_H__
#define __PAGE_H__

#include "Types.h"

//macro

#define PAGE_FLAGS_P		0x00000001
#define PAGE_FLAGS_RW		0x00000002
#define PAGE_FLAGS_US		0x00000004
#define	PAGE_FLAGS_PWT		0x00000008
#define PAGE_FLAGS_PCD		0x00000010
#define PAGE_FLAGS_A		0x00000020
#define PAGE_FLAGS_D		0x00000040
#define PAGE_FLAGS_PS		0x00000080
#define PAGE_FLAGS_G		0x00000100
#define PAGE_FLAGS_PAT		0x00001000
#define PAGE_FLAGS_EXB		0x80000000
#define PAGE_FLAGS_DEFAULT	( PAGE_FLAGS_P | PAGE_FLAGS_RW )
#define PAGE_TABLESIZE		0x1000
#define PAGE_MAXENTRYCOUNT	512
#define PAGE_DEFAULTSIZE	0x200000

//struct
#pragma pack( push, 1 )

typedef struct kPageTableEntryStruct
{
	//--PML4T, PDPTE--
	//1bit P, RW, US, PWT, PCD, A, D, PS< G, 3bit Avail, 1bit PAT, 8bit Reserved, 20bit Base Address
	//--PDE--
	//1bit P, RW, US, PWT, PCD, A, D, 1, G, 3bit Avail, 1bit PAT, 8bit Avail, 11bit Base Address
	DWORD dwAttributeAndLowerBaseAddress;
	//8bit Upper BaseAddress, 12bit Reserved, 11bit Avail, 1bit EXB
	DWORD dwUpperBaseAddressAndEXB;
}	PML4TENTRY, PDPTENTRY, PDENTRY, PTENTRY;

#pragma pack( pop )

//function
void kInitializePageTables( void );
void kSetPageEntryData( PTENTRY* pstEntry, DWORD dwUpperBaseAddress,
		DWORD dwLowerBaseAddress, DWORD dwLowerFlags, DWORD dwUpperFlags );

#endif /*__PAGE_H__*/

