all: BootLoader Kernel32 Disk.img

BootLoader:
	@echo
	@echo ============== Build Boot Loader ===============
	@echo
	
	make -C 00.BootLoader
	
	@echo
	@echo ================ Build Complete ================
	@echo
	
	
Kernel32:
	@echo
	@echo =============== Build 32bit Kernel ===============	
	@echo
	
	make -C 01.Kernel32
	
	@echo
	@echo ================ Build Complete ================
	@echo
	
	
Disk.img: 00.BootLoader/BootLoader.bin 01.Kernel32/Kernel32.bin
	@echo
	@echo =========== Disk Image Build Start ===========
	@echo
	
	./ImageMaker.exe $^
	
	@echo
	@echo ============= ALL Build Complete =============
	@echo
	
Utility:
	@echo
	@echo =========== Utility Build Start ===========
	@echo
	
	make -C 04.Utilty
	
	@echo
	@echo =========== Utility Build Complete ===========
	@echo
	
clean:
	make -C 00.BotLoader clean
	make -C 01.Kernel32 clean
	make -C 04.Utility clean
	rm -f Disk.img 