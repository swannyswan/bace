from enum import unique
import numpy as np

# grass = [-1, 0, 1]
# small_trees = [-1, 0, 1]
# large_trees = [-1, 0, 1]
# interaction = [-1, 0, 1]

all_image_characteristics = np.array([[0, 0, 0, 0],
                                      [0, 1, 0, 0],
                                      [0, 0, 1, 0],
                                      [1, 0, 0, 0],
                                      [1, 1, 0, 1],
                                      [1, 0, 1, 1]])

designs = []

c = 0

for image_1 in all_image_characteristics:
    for image_2 in all_image_characteristics:
        print("combination: ", c)
        print(image_1)
        print(image_2)

        print(" ")

        grass_diff = image_2[0] - image_1[0]
        small_trees_diff = image_2[1] - image_1[1]
        large_trees_diff = image_2[2] - image_1[2]

        if not ((small_trees_diff and large_trees_diff) or
                (small_trees_diff * -1 and large_trees_diff * -1)):
            interaction_1 = image_1[0] and (image_1[1] or image_1[2])
            interaction_2 = image_2[0] and (image_2[1] or image_2[2])
            interaction_diff = interaction_2 - interaction_1
            if not (not grass_diff and not small_trees_diff and not large_trees_diff and not interaction_diff):
                print([grass_diff, small_trees_diff, large_trees_diff, interaction_diff])
                designs.append([grass_diff, small_trees_diff, large_trees_diff, interaction_diff])

        c += 1

print(designs)

designs_flat = [''.join(str(e) + ',' for e in sublist) for sublist in designs]
designs_set = set(''.join(str(e) + ',' for e in sublist) for sublist in designs)
designs_no_repeats = np.array([e.split(',') for e in designs_set])[:, :-1].astype(int)
designs_no_repeats_list = [list(e) for e in designs_no_repeats]

print("number of designs: ", len(designs))
print("designs: ", designs)
print(" ")
print("designs flat length: ", len(designs_flat))
print("designs flat: ", designs_flat)
print(" ")
print("designs set size: ", len(designs_set))
print("designs set: ", designs_set)
print(" ")
print("number of non-repeated designs: ", len(designs_no_repeats))
print("non-repeated designs: ")
print(designs_no_repeats)
print(" ")

unique_designs = []

for design in designs_no_repeats:

    if (list(design) and list(design * -1)) in designs_no_repeats_list:
        if design[0] < 0:
            unique_designs.append(list(design * -1))
            designs_no_repeats_list.remove(list(design))
            designs_no_repeats_list.remove(list(design * -1))
        else:
            unique_designs.append(list(design))
            designs_no_repeats_list.remove(list(design))

            if list(design * -1) in designs_no_repeats_list:
                designs_no_repeats_list.remove(list(design * -1))


print("number of unique designs: ", len(unique_designs))
print("unique designs: ", unique_designs)
print(" ")

print("SQL output:")
for i in range(len(unique_designs)):
    if i < len(unique_designs) - 1:
        print("(ARRAY" + str(unique_designs[i]) + "),")
    else:
        print("(ARRAY" + str(unique_designs[i]) + ");")