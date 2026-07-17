class_name TypedSchemaModels

static func to_flat_object(fields: Array) -> Dictionary:
	var obj := {}
	if fields == null:
		return obj
	for field: Dictionary in fields:
		if field.is_empty() or not field.has("field_name"):
			continue
		var field_name: String = field.get("field_name", "")
		var field_value = field.get("value", null)
		if field_value is Array:
			var field_type: String = field.get("type", "").to_lower()
			if field_type == "object":
				obj[field_name] = to_flat_object(field_value)
			elif field_type == "list" or field_type == "array":
				var arr := []
				for item in field_value:
					if item is Dictionary:
						arr.append(to_flat_object([item]) if item.get("type", "") == "object" else item.get("value", item))
					else:
						arr.append(item)
				obj[field_name] = arr
			else:
				obj[field_name] = field_value
		elif field_value is Dictionary and field.get("type", "").to_lower() == "dict":
			var dict_result := {}
			for key in field_value:
				var sub_field: Dictionary = field_value[key]
				if sub_field is Dictionary:
					dict_result[key] = sub_field.get("value", sub_field)
				else:
					dict_result[key] = sub_field
			obj[field_name] = dict_result
		else:
			obj[field_name] = field_value
	return obj


static func get_field_value(data_fields: Array, field_name: String) -> Variant:
	for field: Dictionary in data_fields:
		if field.get("field_name", "") == field_name:
			return field.get("value", null)
	return null


static func get_field_value_typed(data_fields: Array, field_name: String, default_value: Variant = null) -> Variant:
	var raw = get_field_value(data_fields, field_name)
	if raw == null:
		return default_value
	# Try type coercion
	if default_value is int and raw is String:
		return int(raw) if raw.is_valid_int() else default_value
	if default_value is float and raw is String:
		return float(raw) if raw.is_valid_float() else default_value
	if default_value is bool and raw is String:
		return raw.to_lower() == "true"
	return raw
