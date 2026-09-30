// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract QuanLyThueXe {
    
    // Mức phạt cố định cho mỗi ngày trả trễ
    uint256 public mucPhatMoiNgay = 0.001 ether; 
    
    struct HopDongThueXe {
        address nguoiThue;       
        string xeId;             
        uint256 ngayBatDau;      
        uint256 ngayTraDuKien;   
        uint256 tienCoc;         
        bool daTraXe;            
        uint256 tienHoanLai;     
    }

    mapping(uint256 => HopDongThueXe) public cacHopDong;
    uint256 public hopDongCount = 0;

    function thueXe(string memory _xeId, uint256 _soNgayThue) public payable {
        require(msg.value > 0, "Phai gui tien coc");
        
        // Sử dụng minutes thay vì days để dễ dàng test kịch bản bằng Python
        uint256 thoiGianThue = _soNgayThue * 1 minutes; 
        
        cacHopDong[hopDongCount] = HopDongThueXe({
            nguoiThue: msg.sender,
            xeId: _xeId,
            ngayBatDau: block.timestamp,
            ngayTraDuKien: block.timestamp + thoiGianThue,
            tienCoc: msg.value,
            daTraXe: false,
            tienHoanLai: 0
        });
        
        hopDongCount++;
    }

    function traXe(uint256 _hopDongId) public {
        HopDongThueXe storage hd = cacHopDong[_hopDongId];
        
        require(hd.nguoiThue == msg.sender, "Chi nguoi thue moi duoc tra xe");
        require(!hd.daTraXe, "Xe da duoc tra");
        
        uint256 tienHoan = hd.tienCoc;
        
        // Tính toán phạt nếu trễ hạn (tính theo phút cho mô phỏng)
        if (block.timestamp > hd.ngayTraDuKien) {
            uint256 thoiGianTre = block.timestamp - hd.ngayTraDuKien;
            uint256 soNgayTre = thoiGianTre / 1 minutes; 
            
            uint256 tienPhat = soNgayTre * mucPhatMoiNgay;
            
            if (tienPhat >= tienHoan) {
                tienHoan = 0; 
            } else {
                tienHoan -= tienPhat;
            }
        }
        
        hd.daTraXe = true;
        hd.tienHoanLai = tienHoan;
        
        if (tienHoan > 0) {
            (bool success, ) = payable(msg.sender).call{value: tienHoan}("");
require(success, "Hoan tien that bai");
        }
    }

    function xemChiTietHopDong(uint256 _hopDongId) public view returns (
        address nguoiThue,
        string memory xeId,
        uint256 ngayBatDau,
        uint256 ngayTraDuKien,
        uint256 tienCoc,
        bool daTraXe,
        uint256 tienHoanLai
    ) {
        HopDongThueXe memory hd = cacHopDong[_hopDongId];
        return (
            hd.nguoiThue,
            hd.xeId,
            hd.ngayBatDau,
            hd.ngayTraDuKien,
            hd.tienCoc,
            hd.daTraXe,
            hd.tienHoanLai
        );
    }
}