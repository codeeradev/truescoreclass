class bannerModel {
  String? sId;
  String? bannerId;
  String? image;
  String? title;
  String? createdAt;
  String? updatedAt;
  int? iV;

  bannerModel(
      {this.sId,
        this.bannerId,
        this.image,
        this.title,
        this.createdAt,
        this.updatedAt,
        this.iV});

  bannerModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    bannerId = json['bannerId'];
    image = json['image'];
    title = json['title'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['bannerId'] = this.bannerId;
    data['image'] = this.image;
    data['title'] = this.title;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
