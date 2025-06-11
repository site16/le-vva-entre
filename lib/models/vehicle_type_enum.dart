enum VehicleType {
  moto,
  bike,
  car,
  unknown,
}

VehicleType vehicleTypeFromString(String value) {
  switch (value) {
    case 'moto':
      return VehicleType.moto;
    case 'bike':
      return VehicleType.bike;
    case 'car':
      return VehicleType.car;
    default:
      return VehicleType.unknown;
  }
}

String vehicleTypeToString(VehicleType type) {
  return type.toString().split('.').last;
}