// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract QuanLyThueXe {

    address public chuSoHuu;

    uint256 public mucPhatMoiNgay = 0.001 ether;
    uint256 public mucCoc = 0.01 ether;

    // Don vi thoi gian cho 1 "ngay" thue. Mac dinh 1 days.
    // Co the dat thanh 1 minutes de chay kich ban test.
    uint256 public donViThoiGian = 1 minutes;

    uint256 public tienPhatDaThu;

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
    mapping(string => bool) public xeDangChoThue;
    uint256 public hopDongCount = 0;

    event XeDaThue(
        uint256 indexed hopDongId,
        address indexed nguoiThue,
        string xeId,
        uint256 ngayBatDau,
        uint256 ngayTraDuKien,
        uint256 tienCoc
    );

    event XeDaTra(
        uint256 indexed hopDongId,
        address indexed nguoiThue,
        uint256 soNgayTre,
        uint256 tienPhat,
        uint256 tienHoanLai
    );

    event DaRutTienPhat(address indexed nguoiNhan, uint256 soTien);
    event CapNhatDonViThoiGian(uint256 donViMoi);

    modifier chiChuSoHuu() {
        require(msg.sender == chuSoHuu, "Chi chu so huu moi duoc goi");
        _;
    }

    constructor() {
        chuSoHuu = msg.sender;
    }

    function thueXe(string memory _xeId, uint256 _soNgayThue) public payable {
        require(msg.value == mucCoc, "Tien coc phai dung 0.01 ETH");
        require(_soNgayThue > 0, "So ngay thue phai lon hon 0");
        require(bytes(_xeId).length > 0, "Xe ID khong duoc rong");
        require(!xeDangChoThue[_xeId], "Xe nay dang duoc thue");

        xeDangChoThue[_xeId] = true;

        uint256 thoiGianThue = _soNgayThue * donViThoiGian;
        uint256 hanTra = block.timestamp + thoiGianThue;

        cacHopDong[hopDongCount] = HopDongThueXe({
            nguoiThue: msg.sender,
            xeId: _xeId,
            ngayBatDau: block.timestamp,
            ngayTraDuKien: hanTra,
            tienCoc: msg.value,
            daTraXe: false,
            tienHoanLai: 0
        });

        emit XeDaThue(hopDongCount, msg.sender, _xeId, block.timestamp, hanTra, msg.value);

        hopDongCount++;
    }

    function traXe(uint256 _hopDongId) public {
        require(_hopDongId < hopDongCount, "Hop dong khong ton tai");

        HopDongThueXe storage hd = cacHopDong[_hopDongId];

        require(hd.nguoiThue == msg.sender, "Chi nguoi thue moi duoc tra xe");
        require(!hd.daTraXe, "Xe da duoc tra");

        uint256 tienHoan = hd.tienCoc;
        uint256 soNgayTre = 0;
        uint256 tienPhat = 0;

        if (block.timestamp > hd.ngayTraDuKien) {
            uint256 thoiGianTre = block.timestamp - hd.ngayTraDuKien;
            soNgayTre = thoiGianTre / donViThoiGian;
            tienPhat = soNgayTre * mucPhatMoiNgay;

            if (tienPhat >= tienHoan) {
                tienPhat = tienHoan;
                tienHoan = 0;
            } else {
                tienHoan -= tienPhat;
            }
        }

        // Cap nhat trang thai truoc khi chuyen tien (chong reentrancy)
        hd.daTraXe = true;
        hd.tienHoanLai = tienHoan;
        tienPhatDaThu += tienPhat;
        xeDangChoThue[hd.xeId] = false;

        emit XeDaTra(_hopDongId, msg.sender, soNgayTre, tienPhat, tienHoan);

        if (tienHoan > 0) {
            (bool success, ) = payable(msg.sender).call{value: tienHoan}("");
            require(success, "Hoan tien that bai");
        }
    }

    function rutTienPhat() public chiChuSoHuu {
        uint256 soTien = tienPhatDaThu;
        require(soTien > 0, "Khong co tien phat de rut");

        tienPhatDaThu = 0;

        (bool success, ) = payable(chuSoHuu).call{value: soTien}("");
        require(success, "Rut tien that bai");

        emit DaRutTienPhat(chuSoHuu, soTien);
    }

    function datDonViThoiGian(uint256 _donViMoi) public chiChuSoHuu {
        require(_donViMoi > 0, "Don vi thoi gian phai lon hon 0");
        donViThoiGian = _donViMoi;
        emit CapNhatDonViThoiGian(_donViMoi);
    }

    function xemChiTietHopDong(uint256 _hopDongId)
        public
        view
        returns (HopDongThueXe memory)
    {
        require(_hopDongId < hopDongCount, "Hop dong khong ton tai");
        return cacHopDong[_hopDongId];
    }
}
